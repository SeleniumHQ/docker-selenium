#!/usr/bin/env python3
"""Delete the GHCR image tags a pull request left behind.

build-images.yml publishes one image set per pull request, tagged ``pr-<number>``.
That is 27 images per pull request, useless the moment it closes, and nothing
else removes them.

Two modes:

* ``--pr N`` deletes the tags for one pull request, run when it closes without
  being merged.
* no ``--pr`` sweeps every ``pr-*`` tag whose pull request is closed, run weekly.
  This is what collects merged pull requests, which the close event deliberately
  leaves alone so the trunk run started by the merge can still reuse them, and
  anything the close event missed - a failed run, or a pull request that closed
  before this existed.

GHCR deletes *versions* - manifests - not individual tags, and one manifest
carries both its ``src-<hash>`` tag and the ``pr-<N>`` alias for the pull request
that built it. So ``pr-<N>`` cannot be removed while keeping ``src-<hash>``: they
are the same object. The alias is therefore used as the handle for finding what a
closed pull request left behind, and a version is removed only when every one of
these holds:

* it carries a ``pr-<N>`` tag whose pull request is closed
* it carries no ``pr-<M>`` tag for a pull request that is still open, since two
  pull requests with identical image content share one manifest
* it is not the manifest ``main`` points at
* every tag on it is one of ours, so a release tag, ``latest`` or ``nightly`` can
  never be caught by this even if the API returns one

Each removal takes the whole hash family: the index and the per-architecture
manifests it points at. Those children carry only ``src-<hash>-<arch>`` tags, so
no sweep judges them on their own - and they cannot be, since deleting a child
would break an index that may still be in use.
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

API = "https://api.github.com"
# pr-<N> moves to a pull request's newest build; pr-<N>-<hash> is written once
# per build and never moves, so every manifest a pull request used stays
# attributable to it after the branch is gone.
PR_TAG = re.compile(r"\Apr-(\d+)(?:-([0-9a-f]{6,}))?\Z")
# src-<hash> plus the -complete marker build-images writes on base once the
# whole set has merged. The marker is another tag on the src-<hash> manifest,
# so without it here every base manifest counts as carrying a tag outside the
# CI families and is protected from cleanup for ever.
SRC_TAG = re.compile(r"\Asrc-([0-9a-f]{6,})(?:-complete)?\Z")
# The per-architecture manifests the native build jobs push, which merge_ci_images
# then indexes. They are the children of src-<hash>, not copies of it: deleting one
# on its own breaks an index that may still be in use, so they are never judged
# separately - only deleted alongside the index that references them.
ARCH_TAG = re.compile(r"\Asrc-([0-9a-f]{6,})-(?:amd64|arm64)\Z")
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


def tag_hash(tag):
    """The content hash a CI tag belongs to, or None if it is not one of ours."""
    for pattern in (SRC_TAG, ARCH_TAG):
        match = pattern.match(tag)
        if match:
            return match.group(1)
    match = PR_TAG.match(tag)
    return match.group(2) if match else None


def is_ci_tag(tag):
    return bool(PR_TAG.match(tag) or SRC_TAG.match(tag) or ARCH_TAG.match(tag))


def tags_of(version):
    return version.get("metadata", {}).get("container", {}).get("tags", []) or []


def is_arch_child(version):
    """A version carrying nothing but per-architecture tags."""
    tags = tags_of(version)
    return bool(tags) and all(ARCH_TAG.match(tag) for tag in tags)


def arch_children(all_versions):
    """hash -> the per-architecture manifests the index for that hash points at."""
    children = {}
    for version in all_versions:
        if not is_arch_child(version):
            continue
        for digest in {ARCH_TAG.match(tag).group(1) for tag in tags_of(version)}:
            children.setdefault(digest, []).append(version)
    return children


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


def delete_family(owner, image, version, children, token, dry_run=False):
    """Delete an index manifest together with the per-architecture children it indexes.

    The children carry only src-<hash>-<arch> tags, so no sweep judges them: on
    their own they are invisible, and half of every image's CI tags were piling
    up unreachable. They are also not independent - the index points at them by
    digest - so the only safe time to remove one is when its index goes too.

    The index is deleted first. If the run dies between the two, what is left is
    an unreferenced child a later sweep can still collect, rather than an index
    pointing at a manifest that no longer exists.
    """
    targets, seen = [version], {version["id"]}
    for digest in {tag_hash(tag) for tag in tags_of(version)} - {None}:
        for child in children.get(digest, []):
            # Two hashes that build byte-identical images share one manifest, so
            # this child can also be src-<other>-amd64 - and that other index is
            # not ours to break. Only take a child that belongs to this hash
            # alone.
            if {tag_hash(tag) for tag in tags_of(child)} != {digest}:
                continue
            if child["id"] not in seen:
                seen.add(child["id"])
                targets.append(child)

    removed, problems = 0, []
    for target in targets:
        label = f"{image}:{','.join(sorted(tags_of(target)))}"
        if dry_run:
            print(f"- would delete `{label}`")
            removed += 1
            continue
        try:
            _request(
                f"{API}/orgs/{owner}/packages/container/"
                f"{urllib.parse.quote(image, safe='')}/versions/{target['id']}",
                token,
                method="DELETE",
            )
            removed += 1
        except urllib.error.HTTPError as error:
            problems.append(f"{label} ({error.code})")
    return removed, problems


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


def prune_superseded(owner, image, token, dry_run=False):
    """Remove trunk-built src-* manifests that :main has superseded.

    A trunk build publishes src-<hash> and, once its tests pass, :main is retagged
    onto it. The previous trunk manifests keep their src-* tag for ever: they carry
    no pr-* alias, because only a pull request build creates one, so the
    closed-pull-request sweep can never reach them.

    Superseded means created before whatever :main points at now. That is used
    rather than an age in days because it cannot race: a manifest newer than the
    current main might be mid-promotion in another run, and is left alone.
    """
    all_versions = versions(owner, image, token)
    children = arch_children(all_versions)
    main_version = next(
        (v for v in all_versions if MAIN_TAG in tags_of(v)),
        None,
    )
    if main_version is None:
        return 0, ["no :main tag, so nothing can be judged superseded"]

    main_created = main_version.get("created_at", "")
    removed, problems = 0, []
    for version in all_versions:
        tags = tags_of(version)
        if version["id"] == main_version["id"] or not tags:
            continue
        # Only ever untagged-by-us src-* manifests: a pr-* alias means the
        # pull-request sweep owns it, and anything else is a release tag. The
        # per-architecture children are not judged here either - they go with
        # whichever index references them.
        if any(not SRC_TAG.match(t) for t in tags):
            continue
        if not version.get("created_at") or version["created_at"] >= main_created:
            continue
        count, trouble = delete_family(owner, image, version, children, token, dry_run)
        removed += count
        problems.extend(trouble)
    return removed, problems


def prune_orphans(owner, image, token, older_than_days, dry_run=False):
    """Remove src-* manifests that no pull request and no branch still points at.

    A pull request retags pr-<N> onto each new build, and a tag names one
    manifest, so a pull request with several image-affecting commits leaves its
    earlier manifests carrying only src-*. Nothing else refers to them: the
    closed-pull-request sweep needs a pr-* tag it does not have, and the
    superseded sweep only compares against :main.

    An unaliased src-* is provably unused, because every manifest an open pull
    request depends on is aliased - including one it merely reused. The age guard
    only covers the minutes between a push and its alias landing.
    """
    cutoff = (datetime.now(timezone.utc) - timedelta(days=older_than_days)).isoformat()
    all_versions = versions(owner, image, token)
    children = arch_children(all_versions)
    removed, problems = 0, []
    for version in all_versions:
        tags = tags_of(version)
        if not tags or any(not SRC_TAG.match(t) for t in tags):
            continue
        created = version.get("created_at") or ""
        if not created or created >= cutoff:
            continue
        count, trouble = delete_family(owner, image, version, children, token, dry_run)
        removed += count
        problems.extend(trouble)
    return removed, problems


def main(argv=None):
    parser = argparse.ArgumentParser(description="Delete pr-* image tags from GHCR.")
    parser.add_argument("--owner", required=True)
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", "").split("/")[-1] or "docker-selenium")
    parser.add_argument("--pr", type=int, default=None, help="Only this pull request.")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--no-pr-sweep",
        action="store_true",
        help="Skip the closed-pull-request sweep. Used on trunk, where only --prune-superseded applies.",
    )
    parser.add_argument(
        "--prune-orphans",
        type=int,
        metavar="DAYS",
        default=None,
        help="Also remove src-* manifests with no pr-* alias older than DAYS.",
    )
    parser.add_argument(
        "--prune-superseded",
        action="store_true",
        help="Also remove trunk-built src-* manifests older than what :main points at.",
    )
    args = parser.parse_args(argv)

    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        print("GH_TOKEN is required.", file=sys.stderr)
        return 2

    deleted, kept, failed = 0, 0, []
    open_cache = {}
    protected = 0

    print("## Pull request image cleanup\n")
    for image in [] if args.no_pr_sweep else IMAGES:
        try:
            all_versions = versions(args.owner, image, token)
            children = arch_children(all_versions)
            # Whatever main points at is the promotion source for a release and is
            # never removed, however old the pull request that first built it.
            main_ids = {v["id"] for v in all_versions if MAIN_TAG in tags_of(v)}

            for version in all_versions:
                tags = tags_of(version)
                pr_tags = [t for t in tags if PR_TAG.match(t)]
                if not pr_tags:
                    continue

                numbers = sorted(int(PR_TAG.match(t).group(1)) for t in pr_tags)
                if args.pr is not None and args.pr not in numbers:
                    continue

                # Never touch anything carrying a tag outside the CI families.
                if any(not is_ci_tag(t) for t in tags):
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

                count, trouble = delete_family(
                    args.owner, image, version, children, token, args.dry_run
                )
                deleted += count
                failed.extend(trouble)
        except Exception as error:  # noqa: BLE001 - one bad package must not stop the sweep
            failed.append(f"{image} ({error})")

    if args.prune_superseded:
        print("\n### Superseded trunk images\n")
        pruned = 0
        for image in IMAGES:
            try:
                removed, problems = prune_superseded(args.owner, image, token, args.dry_run)
                pruned += removed
                failed.extend(problems)
            except Exception as error:  # noqa: BLE001 - one bad package must not stop the sweep
                failed.append(f"{image} ({error})")
        print(f"- Superseded manifests deleted: **{pruned}**")

    if args.prune_orphans is not None:
        print(f"\n### Orphaned images older than {args.prune_orphans} days\n")
        orphans = 0
        for image in IMAGES:
            try:
                removed, problems = prune_orphans(args.owner, image, token, args.prune_orphans, args.dry_run)
                orphans += removed
                failed.extend(problems)
            except Exception as error:  # noqa: BLE001 - one bad package must not stop the sweep
                failed.append(f"{image} ({error})")
        print(f"- Orphaned manifests deleted: **{orphans}**")

    scope = "none" if args.no_pr_sweep else (f"PR #{args.pr}" if args.pr is not None else "all closed pull requests")
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
