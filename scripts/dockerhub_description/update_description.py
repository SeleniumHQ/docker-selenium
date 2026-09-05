#!/usr/bin/env python3
"""Publish the Docker Hub overview pages that live in docs/docker-hub/.

Source of truth for https://hub.docker.com/u/selenium. See
specs/dockerhub-image-descriptions/spec.md.
"""

import argparse
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
DOCS_DIR = REPO_ROOT / "docs" / "docker-hub"
FOOTER_FILE = DOCS_DIR / "_footer.md"
MAKEFILE = REPO_ROOT / "Makefile"

SHORT_LIMIT = 100
FULL_LIMIT = 25_000

FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n(.*)\Z", re.DOTALL)


@dataclass
class Description:
    name: str
    short: str
    full: str


def _parse_frontmatter(block, path):
    """Parse the tiny `key: value` frontmatter. Deliberately not YAML - see spec R5."""
    fields = {}
    for line in block.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            raise ValueError(f"{path.name}: frontmatter line is not `key: value`: {line!r}")
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip()
    return fields


def parse_description(path, footer):
    text = path.read_text()
    match = FRONTMATTER_RE.match(text)
    if not match:
        raise ValueError(f"{path.name}: missing `---` YAML frontmatter block at the top of the file")

    fields = _parse_frontmatter(match.group(1), path)
    short = fields.get("description", "")
    if not short:
        raise ValueError(f"{path.name}: frontmatter has no non-empty `description` key")

    body = match.group(2)
    if fields.get("footer", "true").lower() != "false":
        body = body.rstrip() + "\n\n" + footer

    return Description(name=path.stem, short=short, full=body)


def validate(desc):
    problems = []
    if len(desc.short) > SHORT_LIMIT:
        problems.append(f"{desc.name}: short description is {len(desc.short)} chars, limit is {SHORT_LIMIT}")
    if len(desc.full) > FULL_LIMIT:
        problems.append(f"{desc.name}: full description is {len(desc.full)} chars, limit is {FULL_LIMIT}")
    if not desc.full.strip():
        problems.append(f"{desc.name}: full description is empty")
    return problems


IMAGE_RE = re.compile(r"\$\(NAME\)/([a-z0-9._-]+)")


def image_names_from_makefile(makefile):
    return set(IMAGE_RE.findall(makefile.read_text()))


def description_files(docs_dir):
    return sorted(p for p in docs_dir.glob("*.md") if p.name != "README.md" and not p.name.startswith("_"))


def check_drift(docs_dir, makefile):
    documented = {p.stem for p in description_files(docs_dir)}
    built = image_names_from_makefile(makefile)
    problems = []
    for name in sorted(built - documented):
        problems.append(f"{name}: built by the Makefile but has no docs/docker-hub/{name}.md")
    for name in sorted(documented - built):
        problems.append(f"{name}: docs/docker-hub/{name}.md exists but no $(NAME)/{name} image is built")
    return problems


HUB_API = "https://hub.docker.com/v2"


def _request(url, data=None, token=None, method="GET"):
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    payload = json.dumps(data).encode() if data is not None else None
    request = urllib.request.Request(url, data=payload, headers=headers, method=method)
    with urllib.request.urlopen(request, timeout=60) as response:
        raw = response.read().decode()
    # Docker Hub embeds raw control characters in description strings, so strict parsing fails.
    return json.loads(raw, strict=False) if raw else {}


def login(username, secret):
    """Obtain a bearer token. /v2/auth/token accepts a personal access token; /v2/users/login
    accepts an account password. Try the token endpoint first."""
    try:
        response = _request(f"{HUB_API}/auth/token", {"identifier": username, "secret": secret}, method="POST")
        if response.get("access_token"):
            return response["access_token"]
    except urllib.error.HTTPError:
        pass
    response = _request(f"{HUB_API}/users/login", {"username": username, "password": secret}, method="POST")
    if not response.get("token"):
        raise RuntimeError("Docker Hub authentication failed: no token in the response")
    return response["token"]


class HubClient:
    def __init__(self, namespace, token=None):
        self.namespace = namespace
        self.token = token

    def _url(self, name):
        return f"{HUB_API}/repositories/{self.namespace}/{name}/"

    def get(self, name):
        return _request(self._url(name), token=self.token)

    def patch(self, name, short, full):
        _request(self._url(name), {"description": short, "full_description": full}, token=self.token, method="PATCH")


def needs_update(desc, remote):
    return (
        desc.short.rstrip() != (remote.get("description") or "").rstrip()
        or desc.full.rstrip() != (remote.get("full_description") or "").rstrip()
    )


def sync(descs, client, dry_run):
    changed = errors = 0
    prefix = "[dry-run] " if dry_run else ""
    for desc in descs:
        try:
            remote = client.get(desc.name)
            before = len(remote.get("full_description") or "")
            if not needs_update(desc, remote):
                print(f"{prefix}{desc.name:<32} full={before:>6}  unchanged")
                continue
            if not dry_run:
                client.patch(desc.name, desc.short, desc.full)
            changed += 1
            print(f"{prefix}{desc.name:<32} full={before:>6} -> {len(desc.full):<6} CHANGED")
        except Exception as error:  # noqa: BLE001 - one bad repo must not hide the other 29
            errors += 1
            print(f"{prefix}{desc.name:<32} ERROR  {error}")
    return changed, errors


def _load_all(docs_dir, makefile, only):
    footer = FOOTER_FILE.read_text() if FOOTER_FILE.exists() else ""
    problems = check_drift(docs_dir, makefile)
    descs = []
    for path in description_files(docs_dir):
        if only and path.stem not in only:
            continue
        try:
            desc = parse_description(path, footer)
        except ValueError as error:
            problems.append(str(error))
            continue
        problems.extend(validate(desc))
        descs.append(desc)
    return descs, problems


def main(argv=None):
    parser = argparse.ArgumentParser(description="Publish docs/docker-hub/ to Docker Hub.")
    parser.add_argument("--namespace", default=os.environ.get("DOCKER_NAMESPACE") or "selenium")
    parser.add_argument("--repo", action="append", default=[], help="Restrict to this repository; repeatable.")
    parser.add_argument("--dry-run", action="store_true", help="Report what would change; write nothing.")
    parser.add_argument("--check", action="store_true", help="Validate only. No network, no credentials.")
    args = parser.parse_args(argv)

    only = set(args.repo)
    descs, problems = _load_all(DOCS_DIR, MAKEFILE, only)

    if problems:
        for problem in problems:
            print(f"ERROR  {problem}", file=sys.stderr)
        print(f"\n{len(problems)} problem(s) found.", file=sys.stderr)
        return 1

    if args.check:
        print(f"{len(descs)} description(s) valid, no drift against the Makefile.")
        return 0

    username = os.environ.get("DOCKER_USERNAME")
    secret = os.environ.get("DOCKER_PASSWORD")
    if not username or not secret:
        print("DOCKER_USERNAME and DOCKER_PASSWORD must be set.", file=sys.stderr)
        return 2

    token = None if args.dry_run else login(username, secret)
    client = HubClient(args.namespace, token)
    changed, errors = sync(descs, client, args.dry_run)
    verb = "would change" if args.dry_run else "changed"
    print(f"\n{len(descs)} repositories checked, {changed} {verb}, {errors} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
