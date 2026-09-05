#!/usr/bin/env python3
"""Publish the Docker Hub overview pages that live in docs/docker-hub/.

Source of truth for https://hub.docker.com/u/selenium. See
specs/dockerhub-image-descriptions/spec.md.
"""

import pathlib
import re
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
