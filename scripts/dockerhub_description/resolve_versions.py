#!/usr/bin/env python3
"""Resolve the version numbers the Docker Hub "Example of a release" blocks display.

The description files in docs/docker-hub/ keep those blocks as placeholders
(``<Major>.<Minor>.<Patch>``, ``<BrowserMajor>`` and so on). Concrete numbers are
resolved here, written to docs/docker-hub/_versions.json, and substituted at
publish time by update_description.py.

Keeping the placeholders in the Markdown and the numbers in one generated file
means the descriptions cannot go stale on their own: there is a single place to
refresh, it is reviewable in git, and update_tag_in_docs_and_files.sh does not
have to reach inside a tag ladder it cannot parse.

Sources, in order of authority:

* CHANGELOG/<version>/<browser>_<major>.md - written by tag_and_push_browser_images.sh
  during the release, so it records exactly what was tagged. Covers chrome,
  chrome-for-testing, edge and firefox.
* The Docker Hub tag list - used only for chromium, which produces no changelog
  entry because its version is discovered at build time by running the image.

Run via `make update_dockerhub_versions`.
"""

import argparse
import json
import pathlib
import re
import sys
import urllib.request

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
CHANGELOG_DIR = REPO_ROOT / "CHANGELOG"
DOCS_DIR = REPO_ROOT / "docs" / "docker-hub"
VERSIONS_FILE = DOCS_DIR / "_versions.json"

HUB_API = "https://hub.docker.com/v2"

RELEASE_DIR_RE = re.compile(r"\A\d+\.\d+\.\d+\Z")
SHORT_RE = re.compile(r"Short (.+?) version -> (\S+)")
GRID_RE = re.compile(r"Selenium Grid version -> (\S+)")

# browser key -> (changelog prefix, label in the "Short <label> version" line, driver label)
CHANGELOG_BROWSERS = {
    "chrome": ("chrome", "Chrome", "ChromeDriver"),
    "chrome-for-testing": ("chrome-for-testing", "Chrome for Testing", "ChromeDriver"),
    "edge": ("edge", "Edge", "EdgeDriver"),
    "firefox": ("firefox", "Firefox", "GeckoDriver"),
}

# chromium ships no changelog entry, so its numbers come from the published tags
CHROMIUM_REPO = "standalone-chromium"
CHROMIUM_SHORT_RE = re.compile(r"\A(\d+\.\d+)-chromedriver-(\d+\.\d+)\Z")
CHROMIUM_FULL_RE = re.compile(r"\A(\d+\.\d+\.\d+\.\d+)-chromedriver-(\d+\.\d+\.\d+\.\d+)\Z")


def latest_release_dir(changelog_dir):
    """The newest CHANGELOG/<x.y.z>/ directory. 'archived' and stray names are ignored."""
    releases = [p for p in changelog_dir.iterdir() if p.is_dir() and RELEASE_DIR_RE.match(p.name)]
    if not releases:
        raise RuntimeError(f"no CHANGELOG/<version>/ directory found under {changelog_dir}")
    return max(releases, key=lambda p: [int(part) for part in p.name.split(".")])


def newest_changelog(release_dir, prefix):
    """The highest-numbered <prefix>_<major>.md in a release directory, or None."""
    pattern = re.compile(rf"\A{re.escape(prefix)}_([\d.]+)\.md\Z")
    matches = []
    for path in release_dir.glob(f"{prefix}_*.md"):
        found = pattern.match(path.name)
        if found:
            matches.append(([int(part) for part in found.group(1).split(".")], path))
    if not matches:
        return None
    return max(matches)[1]


def parse_changelog(path):
    """Pull the 'Short <x> version' and 'Selenium Grid version' lines out of a changelog."""
    fields = {}
    for line in path.read_text().splitlines():
        short = SHORT_RE.match(line)
        if short:
            fields[short.group(1)] = short.group(2)
        grid = GRID_RE.match(line)
        if grid:
            fields["grid_tag"] = grid.group(1)
    return fields


def _hub_tags(namespace, repo):
    url = f"{HUB_API}/repositories/{namespace}/{repo}/tags/?page_size=100&ordering=last_updated"
    with urllib.request.urlopen(url, timeout=60) as response:
        payload = json.loads(response.read().decode(), strict=False)
    return [tag["name"] for tag in payload.get("results", [])]


def chromium_versions(namespace):
    """Chromium's numbers, read from the tags it actually published.

    Its version is only known at build time (tag_and_push_browser_images.sh runs
    `chromium --version` inside the image), so there is no changelog to read. Do
    not infer it from Chrome: the two diverge on the build component, and an
    inferred 152.0.7977.82 was a tag that did not exist while the real one was
    152.0.7977.75.
    """
    tags = _hub_tags(namespace, CHROMIUM_REPO)
    short = next((CHROMIUM_SHORT_RE.match(t) for t in tags if CHROMIUM_SHORT_RE.match(t)), None)
    full = next((CHROMIUM_FULL_RE.match(t) for t in tags if CHROMIUM_FULL_RE.match(t)), None)
    if not short or not full:
        raise RuntimeError(f"could not find browser-and-driver tags for selenium/{CHROMIUM_REPO}")
    return {
        "browser": short.group(1),
        "driver": short.group(2),
        "browser_full": full.group(1),
        "driver_full": full.group(2),
    }


def resolve(changelog_dir, namespace, skip_chromium=False, grid_tag_override=None):
    release_dir = latest_release_dir(changelog_dir)
    browsers, problems = {}, []
    grid_tag = None

    for key, (prefix, browser_label, driver_label) in sorted(CHANGELOG_BROWSERS.items()):
        path = newest_changelog(release_dir, prefix)
        if path is None:
            problems.append(f"{key}: no {prefix}_*.md in {release_dir.name}")
            continue
        fields = parse_changelog(path)
        if browser_label not in fields or driver_label not in fields:
            problems.append(f"{key}: {path.name} has no 'Short {browser_label}/{driver_label} version' line")
            continue
        browsers[key] = {"browser": fields[browser_label], "driver": fields[driver_label]}
        grid_tag = grid_tag or fields.get("grid_tag")

    grid_tag = grid_tag_override or grid_tag
    if grid_tag is None:
        problems.append(f"no 'Selenium Grid version ->' line found in {release_dir}")
        return None, problems

    if not skip_chromium:
        try:
            browsers["chromium"] = chromium_versions(namespace)
        except Exception as error:  # noqa: BLE001 - network failure must be reported, not fatal-by-traceback
            problems.append(f"chromium: could not resolve from the registry: {error}")

    version, _, date = grid_tag.rpartition("-")
    major, minor, patch = version.split(".")
    return {
        "_comment": "Generated by scripts/dockerhub_description/resolve_versions.py. "
        "Run `make update_dockerhub_versions`. Do not edit by hand.",
        "release": release_dir.name,
        "grid": {
            "tag": grid_tag,
            "version": version,
            "date": date,
            "major": major,
            "major_minor": f"{major}.{minor}",
            "patch": patch,
        },
        "browsers": dict(sorted(browsers.items())),
    }, problems


def main(argv=None):
    parser = argparse.ArgumentParser(description="Resolve versions for the Docker Hub example blocks.")
    parser.add_argument("--namespace", default="selenium")
    parser.add_argument("--skip-chromium", action="store_true", help="Do not contact the registry for chromium.")
    parser.add_argument("--check", action="store_true", help="Fail if the generated file is out of date.")
    parser.add_argument(
        "--grid-tag",
        default=None,
        help="Grid tag to record, e.g. 4.48.0-20260909. Overrides the CHANGELOG, for use during a "
        "release when the new CHANGELOG entry does not exist yet.",
    )
    args = parser.parse_args(argv)

    if args.grid_tag and not re.fullmatch(r"\d+\.\d+\.\d+-\d{8}", args.grid_tag):
        print(f"--grid-tag must look like 4.48.0-20260909, got {args.grid_tag!r}", file=sys.stderr)
        return 1

    resolved, problems = resolve(CHANGELOG_DIR, args.namespace, args.skip_chromium, args.grid_tag)
    for problem in problems:
        print(f"WARNING  {problem}", file=sys.stderr)
    if resolved is None:
        return 1

    rendered = json.dumps(resolved, indent=2) + "\n"
    if args.check:
        current = VERSIONS_FILE.read_text() if VERSIONS_FILE.exists() else ""
        if current != rendered:
            print(f"{VERSIONS_FILE.name} is out of date. Run `make update_dockerhub_versions`.", file=sys.stderr)
            return 1
        print(f"{VERSIONS_FILE.name} is up to date (release {resolved['release']}).")
        return 0

    VERSIONS_FILE.write_text(rendered)
    grid = resolved["grid"]
    print(f"{VERSIONS_FILE.relative_to(REPO_ROOT)}  release {resolved['release']}  grid {grid['tag']}")
    for name, values in resolved["browsers"].items():
        extra = f"  full {values['browser_full']}" if "browser_full" in values else ""
        print(f"  {name:<20} browser {values['browser']:<8} driver {values['driver']:<8}{extra}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
