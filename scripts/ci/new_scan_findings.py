#!/usr/bin/env python3
"""Lists Trivy findings that are in the head scan but not in the base scan.

Both arguments are SARIF reports. A finding is identified by its rule, file and message,
not by its line, so code that only moves does not count as new. Exits with 1 when the
head scan has new findings, so a change fails only on what it introduces.

Usage: new_scan_findings.py <base.sarif> <head.sarif>
"""

import json
import sys
from collections import Counter


def findings(path):
    """Returns a Counter of (rule, file, message) for every result in a SARIF report."""
    with open(path, encoding="utf-8") as f:
        report = json.load(f)
    found = Counter()
    for run in report.get("runs", []):
        for result in run.get("results", []):
            locations = result.get("locations") or [{}]
            uri = locations[0].get("physicalLocation", {}).get("artifactLocation", {}).get("uri", "")
            message = result.get("message", {}).get("text", "")
            found[(result.get("ruleId", ""), uri, message)] += 1
    return found


def new_findings(base_path, head_path):
    """Returns the findings of the head report that the base report does not have."""
    return findings(head_path) - findings(base_path)


def main(argv):
    if len(argv) != 3:
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    new = new_findings(argv[1], argv[2])
    if not new:
        print("No new findings compared to the base commit.")
        return 0
    print(f"{sum(new.values())} new finding(s) compared to the base commit:")
    for (rule, uri, message), count in sorted(new.items()):
        first_line = message.splitlines()[0] if message else ""
        suffix = f" (x{count})" if count > 1 else ""
        print(f"- {rule} in {uri}: {first_line}{suffix}")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
