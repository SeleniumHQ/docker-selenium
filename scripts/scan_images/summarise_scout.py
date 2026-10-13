#!/usr/bin/env python3
"""Turn Docker Scout's SARIF output into a maintainer-facing summary.

Two modes:

* ``summarise_scout.py <file.sarif> <image>`` - one image, written under a
  heading in the job summary.
* ``summarise_scout.py --rollup <dir>`` - every report in a directory, rolled
  into one table so a maintainer can see the whole surface without opening 26
  matrix jobs.

The scan is run with ``--only-fixed``, so everything reported here has a fix
available upstream. That is the point: an unfixable CVE is not an action, and
mixing the two is how a security report becomes noise.

Parsing sticks to fields the SARIF specification requires, with fallbacks, rather
than to Scout's internal shape. ``security-severity`` is GitHub's convention and
is what the Security tab itself sorts on; ``level`` is plain SARIF. If a future
Scout release moves its extras around, the counts still come out.
"""

import argparse
import json
import pathlib
import re
import sys

SEVERITY_ORDER = ["critical", "high", "medium", "low", "unknown"]

# GitHub's security-severity is a CVSS base score. These are its documented bands.
SCORE_BANDS = [(9.0, "critical"), (7.0, "high"), (4.0, "medium"), (0.1, "low")]

# Plain SARIF levels, used when no score is present.
LEVEL_TO_SEVERITY = {"error": "high", "warning": "medium", "note": "low", "none": "unknown"}

CVE_RE = re.compile(r"CVE-\d{4}-\d+", re.IGNORECASE)
FIXED_IN_RE = re.compile(r"fixed(?:\s+in|\s+version)?[:\s]+([^\s,;)]+)", re.IGNORECASE)


def severity_of(rule, result):
    """Best available severity for a finding, most trustworthy source first."""
    props = (rule or {}).get("properties", {})
    raw = props.get("security-severity")
    if raw is not None:
        try:
            score = float(raw)
        except (TypeError, ValueError):
            score = None
        if score is not None:
            for threshold, label in SCORE_BANDS:
                if score >= threshold:
                    return label
            return "unknown"

    for tag in props.get("tags", []) or []:
        if str(tag).lower() in SEVERITY_ORDER:
            return str(tag).lower()

    level = (result or {}).get("level") or (rule or {}).get("defaultConfiguration", {}).get("level")
    return LEVEL_TO_SEVERITY.get(level, "unknown")


def _text(node, *keys):
    for key in keys:
        value = (node or {}).get(key)
        if isinstance(value, dict) and value.get("text"):
            return value["text"]
        if isinstance(value, str) and value:
            return value
    return ""


def parse_sarif(payload):
    """(findings, problems). A finding is one fixable CVE in one package."""
    findings, problems = [], []
    runs = payload.get("runs") or []
    if not runs:
        return findings, ["report contains no runs"]

    for run in runs:
        rules = {r.get("id"): r for r in (run.get("tool", {}).get("driver", {}).get("rules") or [])}
        for result in run.get("results") or []:
            rule_id = result.get("ruleId") or ""
            rule = rules.get(rule_id, {})
            blob = " ".join(
                filter(
                    None,
                    [
                        rule_id,
                        _text(result, "message"),
                        _text(rule, "shortDescription", "fullDescription"),
                        _text(rule, "help"),
                    ],
                )
            )
            cve = CVE_RE.search(blob)
            fixed = FIXED_IN_RE.search(blob)
            findings.append(
                {
                    "id": cve.group(0).upper() if cve else (rule_id or "unknown"),
                    "severity": severity_of(rule, result),
                    "package": _package_of(result) or _text(rule, "shortDescription") or "-",
                    "fixed_in": fixed.group(1) if fixed else "",
                }
            )
    return findings, problems


def _package_of(result):
    """The artifact a finding sits in, from the standard location structure."""
    for location in result.get("locations") or []:
        uri = (
            location.get("physicalLocation", {})
            .get("artifactLocation", {})
            .get("uri")
        )
        if uri:
            return uri
    return ""


def counts(findings):
    tally = {name: 0 for name in SEVERITY_ORDER}
    for finding in findings:
        tally[finding["severity"]] = tally.get(finding["severity"], 0) + 1
    return tally


def _load(path):
    try:
        return json.loads(pathlib.Path(path).read_text()), None
    except FileNotFoundError:
        return None, f"{path}: not found"
    except json.JSONDecodeError as error:
        return None, f"{path}: not valid JSON ({error})"


def summarise_one(path, image):
    payload, error = _load(path)
    if error:
        return f"Could not read the Scout report - {error}\n"

    findings, problems = parse_sarif(payload)
    tally = counts(findings)
    lines = []

    if not findings:
        lines.append("No CVEs with a fix available. :tada:\n")
        return "\n".join(lines)

    lines.append("| Severity | Fixable |")
    lines.append("| --- | ---: |")
    for name in SEVERITY_ORDER:
        if tally.get(name):
            lines.append(f"| {name.capitalize()} | {tally[name]} |")
    lines.append("")

    actionable = [f for f in findings if f["severity"] in ("critical", "high")]
    if actionable:
        lines.append("<details><summary>Critical and high, with fixes</summary>")
        lines.append("")
        lines.append("| CVE | Severity | Package | Fixed in |")
        lines.append("| --- | --- | --- | --- |")
        for finding in sorted(actionable, key=lambda f: (SEVERITY_ORDER.index(f["severity"]), f["id"]))[:50]:
            fixed = finding["fixed_in"] or "see report"
            lines.append(f"| {finding['id']} | {finding['severity']} | `{finding['package']}` | {fixed} |")
        if len(actionable) > 50:
            lines.append(f"| … | | | {len(actionable) - 50} more in the SARIF artifact |")
        lines.append("")
        lines.append("</details>")
        lines.append("")

    for problem in problems:
        lines.append(f"> {problem}")
    return "\n".join(lines) + "\n"


# Replaced once the tally is known; the status has to sit above the table, but
# cannot be computed until every report has been read.
STATUS_PLACEHOLDER = object()


def _plural(count, noun):
    return f"{count} {noun}" if count == 1 else f"{count} {noun}s"


def _status_line(totals, affected, scanned):
    """The one line a maintainer should be able to act on without reading further."""
    scope = f"across {affected} of {_plural(scanned, 'image')}"
    if totals["critical"]:
        return (
            f"**Status: ACTION NEEDED** — {totals['critical']} critical and {totals['high']} high "
            f"with fixes available, {scope}."
        )
    if totals["high"]:
        return (
            f"**Status: ACTION NEEDED** — {totals['high']} high with fixes available, "
            f"{scope}."
        )
    if affected:
        return (
            f"**Status: OK** — nothing critical or high. {sum(totals.values())} lower-severity "
            f"findings have fixes available, {scope}."
        )
    return f"**Status: CLEAN** — no CVEs with a fix available across {_plural(scanned, 'image')}."


def summarise_rollup(directory, tag, severity):
    root = pathlib.Path(directory)
    reports = sorted(root.glob("**/*.sarif"))
    lines = [f"## Fixable CVEs in `:{tag}` images", ""]

    if not reports:
        lines.append(
            "No Scout reports were produced. The most likely cause is that Docker Scout is not "
            "enabled for these repositories - check `docker scout repo list`."
        )
        return "\n".join(lines) + "\n"

    lines.append(f"Reporting severities: **{severity}**. Every CVE listed has a fix available upstream.")
    lines.append("")
    lines.append(STATUS_PLACEHOLDER)
    lines.append("")
    lines.append("| Image | Critical | High | Medium | Low | Total fixable |")
    lines.append("| --- | ---: | ---: | ---: | ---: | ---: |")

    totals = {name: 0 for name in SEVERITY_ORDER}
    rows, unreadable = [], []
    for report in reports:
        payload, error = _load(report)
        if error:
            unreadable.append(report.name)
            continue
        findings, _ = parse_sarif(payload)
        tally = counts(findings)
        for name in SEVERITY_ORDER:
            totals[name] += tally.get(name, 0)
        image = report.stem.replace("scout-", "")
        rows.append((tally.get("critical", 0), tally.get("high", 0), image, tally, len(findings)))

    # Worst first: an empty report at the top of a long table hides the one that matters.
    for _, _, image, tally, total in sorted(rows, key=lambda r: (-r[0], -r[1], r[2])):
        cells = " | ".join(str(tally.get(name, 0)) for name in ["critical", "high", "medium", "low"])
        lines.append(f"| `{image}` | {cells} | {total} |")

    affected = sum(1 for row in rows if row[4])
    status = _status_line(totals, affected, len(rows))
    lines = [status if line is STATUS_PLACEHOLDER else line for line in lines]

    grand = sum(totals.values())
    cells = " | ".join(str(totals[name]) for name in ["critical", "high", "medium", "low"])
    lines.append(f"| **Total** | {cells} | **{grand}** |")
    lines.append("")

    if totals["critical"] or totals["high"]:
        lines.append(
            "Most of these will come from a shared base layer, so bumping the base image usually clears "
            "the same CVE across every descendant at once - start with `base` and `node-base`."
        )
        lines.append("")
    lines.append("Per-CVE detail is in the Security tab, and in the `scout-<image>` artifacts on this run.")

    if unreadable:
        lines.append("")
        lines.append(f"> Could not read: {', '.join(unreadable)}")
    return "\n".join(lines) + "\n"


def main(argv=None):
    parser = argparse.ArgumentParser(description="Summarise Docker Scout SARIF output.")
    parser.add_argument("sarif", nargs="?", help="A single SARIF file.")
    parser.add_argument("image", nargs="?", help="Image the SARIF describes.")
    parser.add_argument("--rollup", metavar="DIR", help="Roll up every SARIF under DIR instead.")
    parser.add_argument("--tag", default="nightly")
    parser.add_argument("--severity", default="critical,high")
    args = parser.parse_args(argv)

    if args.rollup:
        sys.stdout.write(summarise_rollup(args.rollup, args.tag, args.severity))
        return 0
    if not args.sarif:
        parser.error("give a SARIF file, or --rollup DIR")
    sys.stdout.write(summarise_one(args.sarif, args.image or args.sarif))
    return 0


if __name__ == "__main__":
    sys.exit(main())
