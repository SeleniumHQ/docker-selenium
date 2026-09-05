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

GHCR deletes *versions* - manifests - not individual tags, and one manifest
carries both its ``src-<hash>`` tag and the ``pr-<N>`` alias for the pull request
that built it. So ``pr-<N>`` cannot be removed while keeping ``src-<hash>``: they
are the same object. The alias is therefore used as the handle for finding what a
closed pull request left behind, and a version is removed only when every one of
these holds:

* it carries a ``pr-<N>`` tag whose pull request is closed
* it carries no ``pr-<M>`` tag for a pull request that is still open, since two
  pull requests with identical image content share one manifest
* it is not the manifest ``main`` points at, which is the release promotion source
* every tag on it is ``pr-*`` or ``src-*``, so a release tag, ``latest`` or
  ``nightly`` can never be caught by this even if the API returns one
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
SRC_TAG = re.compile(r"\Asrc-[0-9a-f]{6,}\Z")
MAIN_TAG = "main"

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
    protected = 0

    print("## Pull request image cleanup\n")
    for image in IMAGES:
        try:
            all_versions = versions(args.owner, image, token)
            # Whatever main points at is the promotion source for a release and is
            # never removed, however old the pull request that first built it.
            main_ids = {
                v["id"]
                for v in all_versions
                if MAIN_TAG in (v.get("metadata", {}).get("container", {}).get("tags", []) or [])
            }

            for version in all_versions:
                tags = version.get("metadata", {}).get("container", {}).get("tags", []) or []
                pr_tags = [t for t in tags if PR_TAG.match(t)]
                if not pr_tags:
                    continue

                numbers = sorted(int(PR_TAG.match(t).group(1)) for t in pr_tags)
                if args.pr is not None and args.pr not in numbers:
                    continue

                # Never touch anything carrying a tag outside the two CI families.
                if any(not (PR_TAG.match(t) or SRC_TAG.match(t)) for t in tags):
                    protected += 1
                    continue

                if version["id"] in main_ids:
                    protected += 1
                    continue

                # Identical image content is one manifest, so a second pull request
                # can be sharing it. Keep it while any of them is still open.
                still_open = False
                for number in numbers:
                    if number not in open_cache:
                        open_cache[number] = pr_is_open(args.owner, args.repo, number, token)
                    if open_cache[number]:
                        still_open = True
                if still_open:
                    kept += 1
                    continue

                if args.dry_run:
                    print(f"- would delete `{image}:{','.join(sorted(tags))}`")
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
                    failed.append(f"{image}:{','.join(sorted(tags))} ({error.code})")
        except Exception as error:  # noqa: BLE001 - one bad package must not stop the sweep
            failed.append(f"{image} ({error})")

    scope = f"PR #{args.pr}" if args.pr is not None else "all closed pull requests"
    print(f"Scope: {scope}\n")
    print(f"- Deleted: **{deleted}**")
    if kept:
        print(f"- Kept (a sharing pull request is still open): {kept}")
    if protected:
        print(f"- Protected (points at `main`, or carries a non-CI tag): {protected}")
    if failed:
        print(f"- Failed: {len(failed)}")
        for item in failed[:20]:
            print(f"  - {item}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
