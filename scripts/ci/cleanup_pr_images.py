#!/usr/bin/env python3
"""Delete the GHCR image tags a pull request left behind.

build-images.yml publishes one image set per pull request, tagged ``pr-<number>``.
That is 27 images per pull request, useless the moment it closes, and nothing
else removes them.

Two modes:

* ``--pr N`` deletes the tags for one pull request, run when it closes.
* no ``--pr`` sweeps every ``pr-*`` tag whose pull request is closed, run weekly
  to catch anything the close event missed - a failed run, or a pull request that
  closed before this existed.

Only ever deletes tags matching ``pr-<digits>``. A version tag, ``main``, or
anything else is not something this touches, whatever the API returns.
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.github.com"
PR_TAG = re.compile(r"\Apr-(\d+)\Z")

# Kept in step with CI_IMAGES in the Makefile.
IMAGES = [
    "base", "hub", "distributor", "router", "sessions", "session-queue", "event-bus",
    "node-base", "node-chrome", "node-chrome-for-testing", "node-chromium", "node-edge",
    "node-firefox", "node-all-browsers", "node-docker", "node-kubernetes",
    "standalone-chrome", "standalone-chrome-for-testing", "standalone-chromium",
    "standalone-edge", "standalone-firefox", "standalone-all-browsers",
    "standalone-docker", "standalone-kubernetes", "video", "keda-external-scaler",
]


def _request(url, token, method="GET"):
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
        method=method,
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        body = response.read().decode()
    return json.loads(body) if body else None


def versions(owner, image, token):
    """Every published version of one package, with its tags."""
    out, page = [], 1
    while True:
        url = (
            f"{API}/orgs/{owner}/packages/container/{urllib.parse.quote(image, safe='')}"
            f"/versions?per_page=100&page={page}"
        )
        try:
            batch = _request(url, token)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return []  # package does not exist; nothing to clean
            raise
        if not batch:
            return out
        out += batch
        page += 1


def pr_is_open(owner, repo, number, token):
    try:
        return _request(f"{API}/repos/{owner}/{repo}/pulls/{number}", token)["state"] == "open"
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return False
        raise


def main(argv=None):
    parser = argparse.ArgumentParser(description="Delete pr-* image tags from GHCR.")
    parser.add_argument("--owner", required=True)
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", "").split("/")[-1] or "docker-selenium")
    parser.add_argument("--pr", type=int, default=None, help="Only this pull request.")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        print("GH_TOKEN is required.", file=sys.stderr)
        return 2

    deleted, kept, failed = 0, 0, []
    open_cache = {}

    print("## Pull request image cleanup\n")
    for image in IMAGES:
        try:
            for version in versions(args.owner, image, token):
                tags = version.get("metadata", {}).get("container", {}).get("tags", []) or []
                targets = [t for t in tags if PR_TAG.match(t)]
                if not targets:
                    continue
                number = int(PR_TAG.match(targets[0]).group(1))

                if args.pr is not None and number != args.pr:
                    continue
                if args.pr is None:
                    if number not in open_cache:
                        open_cache[number] = pr_is_open(args.owner, args.repo, number, token)
                    if open_cache[number]:
                        kept += 1
                        continue

                # A version can carry several tags; only delete when every tag on
                # it is a pr-* tag, so a shared manifest is never removed.
                if set(tags) != set(targets):
                    kept += 1
                    continue

                if args.dry_run:
                    print(f"- would delete `{image}:{','.join(targets)}`")
                    deleted += 1
                    continue
                try:
                    _request(
                        f"{API}/orgs/{args.owner}/packages/container/"
                        f"{urllib.parse.quote(image, safe='')}/versions/{version['id']}",
                        token,
                        method="DELETE",
                    )
                    deleted += 1
                except urllib.error.HTTPError as error:
                    failed.append(f"{image}:{','.join(targets)} ({error.code})")
        except Exception as error:  # noqa: BLE001 - one bad package must not stop the sweep
            failed.append(f"{image} ({error})")

    scope = f"PR #{args.pr}" if args.pr is not None else "all closed pull requests"
    print(f"Scope: {scope}\n")
    print(f"- Deleted: **{deleted}**")
    if kept:
        print(f"- Kept (pull request still open, or tag shared): {kept}")
    if failed:
        print(f"- Failed: {len(failed)}")
        for item in failed[:20]:
            print(f"  - {item}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
