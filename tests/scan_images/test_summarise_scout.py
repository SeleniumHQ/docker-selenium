import importlib.util
import json
import pathlib
import tempfile
import unittest

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "scan_images" / "summarise_scout.py"
spec = importlib.util.spec_from_file_location("summarise_scout", MODULE_PATH)
ss = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ss)


def sarif(results, rules):
    return {
        "version": "2.1.0",
        "runs": [{"tool": {"driver": {"name": "docker scout", "rules": rules}}, "results": results}],
    }


def rule(rule_id, security_severity=None, tags=None, level=None, help_text=""):
    node = {"id": rule_id, "shortDescription": {"text": rule_id}, "properties": {}}
    if security_severity is not None:
        node["properties"]["security-severity"] = security_severity
    if tags:
        node["properties"]["tags"] = tags
    if level:
        node["defaultConfiguration"] = {"level": level}
    if help_text:
        node["help"] = {"text": help_text}
    return node


def result(rule_id, message="", uri="", level=None):
    node = {"ruleId": rule_id, "message": {"text": message}}
    if uri:
        node["locations"] = [{"physicalLocation": {"artifactLocation": {"uri": uri}}}]
    if level:
        node["level"] = level
    return node


class SeverityTest(unittest.TestCase):
    def test_cvss_score_bands_map_to_labels(self):
        for score, expected in [
            ("9.8", "critical"),
            ("9.0", "critical"),
            ("7.5", "high"),
            ("7.0", "high"),
            ("5.0", "medium"),
            ("4.0", "medium"),
            ("1.0", "low"),
            ("0.1", "low"),
        ]:
            self.assertEqual(ss.severity_of(rule("x", security_severity=score), {}), expected, score)

    def test_zero_score_is_unknown_not_low(self):
        self.assertEqual(ss.severity_of(rule("x", security_severity="0.0"), {}), "unknown")

    def test_falls_back_to_tags_when_no_score(self):
        self.assertEqual(ss.severity_of(rule("x", tags=["CRITICAL"]), {}), "critical")

    def test_falls_back_to_sarif_level_when_no_score_or_tag(self):
        self.assertEqual(ss.severity_of(rule("x"), {"level": "error"}), "high")
        self.assertEqual(ss.severity_of(rule("x"), {"level": "note"}), "low")

    def test_unparseable_score_does_not_raise(self):
        self.assertEqual(ss.severity_of(rule("x", security_severity="not-a-number"), {}), "unknown")

    def test_missing_everything_is_unknown(self):
        self.assertEqual(ss.severity_of({}, {}), "unknown")


class ParseTest(unittest.TestCase):
    def test_extracts_cve_severity_package_and_fix(self):
        payload = sarif(
            [result("CVE-2026-1234", message="Fixed in 1.2.3", uri="usr/lib/libfoo.so")],
            [rule("CVE-2026-1234", security_severity="9.8")],
        )
        findings, problems = ss.parse_sarif(payload)
        self.assertEqual(problems, [])
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0]["id"], "CVE-2026-1234")
        self.assertEqual(findings[0]["severity"], "critical")
        self.assertEqual(findings[0]["package"], "usr/lib/libfoo.so")
        self.assertEqual(findings[0]["fixed_in"], "1.2.3")

    def test_finds_the_cve_in_help_text_when_the_rule_id_is_opaque(self):
        payload = sarif(
            [result("SNYK-123")],
            [rule("SNYK-123", security_severity="7.5", help_text="See CVE-2026-9999 for detail")],
        )
        findings, _ = ss.parse_sarif(payload)
        self.assertEqual(findings[0]["id"], "CVE-2026-9999")

    def test_keeps_the_rule_id_when_no_cve_is_present(self):
        payload = sarif([result("GHSA-abcd")], [rule("GHSA-abcd", security_severity="5.0")])
        findings, _ = ss.parse_sarif(payload)
        self.assertEqual(findings[0]["id"], "GHSA-abcd")

    def test_missing_fix_version_is_empty_not_an_error(self):
        payload = sarif([result("CVE-2026-1", message="no fix mentioned")], [rule("CVE-2026-1")])
        findings, _ = ss.parse_sarif(payload)
        self.assertEqual(findings[0]["fixed_in"], "")

    def test_report_with_no_runs_is_reported(self):
        findings, problems = ss.parse_sarif({"version": "2.1.0"})
        self.assertEqual(findings, [])
        self.assertEqual(len(problems), 1)

    def test_empty_results_is_a_clean_report_not_a_problem(self):
        findings, problems = ss.parse_sarif(sarif([], []))
        self.assertEqual(findings, [])
        self.assertEqual(problems, [])


class CountsTest(unittest.TestCase):
    def test_tallies_every_severity(self):
        findings = [{"severity": s} for s in ["critical", "high", "high", "low"]]
        tally = ss.counts(findings)
        self.assertEqual(tally["critical"], 1)
        self.assertEqual(tally["high"], 2)
        self.assertEqual(tally["low"], 1)
        self.assertEqual(tally["medium"], 0)


class SummariseOneTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = pathlib.Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def write(self, name, payload):
        path = self.tmp / name
        path.write_text(json.dumps(payload))
        return path

    def test_clean_report_says_so(self):
        path = self.write("scout-hub.sarif", sarif([], []))
        out = ss.summarise_one(path, "selenium/hub:nightly")
        self.assertIn("No CVEs with a fix available", out)

    def test_lists_critical_and_high_with_the_fix_version(self):
        payload = sarif(
            [result("CVE-2026-1", message="Fixed in 2.0", uri="usr/bin/thing")],
            [rule("CVE-2026-1", security_severity="9.8")],
        )
        out = ss.summarise_one(self.write("scout-base.sarif", payload), "selenium/base:nightly")
        self.assertIn("CVE-2026-1", out)
        self.assertIn("critical", out)
        self.assertIn("2.0", out)
        self.assertIn("usr/bin/thing", out)

    def test_missing_file_is_reported_not_raised(self):
        out = ss.summarise_one(self.tmp / "absent.sarif", "selenium/hub:nightly")
        self.assertIn("Could not read", out)

    def test_invalid_json_is_reported_not_raised(self):
        path = self.tmp / "bad.sarif"
        path.write_text("{not json")
        self.assertIn("Could not read", ss.summarise_one(path, "selenium/hub:nightly"))


class RollupTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = pathlib.Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def write(self, image, results, rules):
        d = self.tmp / f"scout-{image}"
        d.mkdir(parents=True)
        (d / f"scout-{image}.sarif").write_text(json.dumps(sarif(results, rules)))

    def test_no_reports_points_at_the_likeliest_cause(self):
        out = ss.summarise_rollup(self.tmp, "nightly", "critical,high")
        self.assertIn("not enabled", out)
        self.assertIn("docker scout repo list", out)

    def test_worst_image_is_listed_first(self):
        self.write("quiet", [], [])
        self.write(
            "noisy",
            [result("CVE-2026-1"), result("CVE-2026-2")],
            [rule("CVE-2026-1", security_severity="9.8"), rule("CVE-2026-2", security_severity="9.8")],
        )
        out = ss.summarise_rollup(self.tmp, "nightly", "critical,high")
        self.assertLess(out.index("`noisy`"), out.index("`quiet`"))

    def test_totals_row_sums_every_image(self):
        self.write("a", [result("CVE-2026-1")], [rule("CVE-2026-1", security_severity="9.8")])
        self.write("b", [result("CVE-2026-2")], [rule("CVE-2026-2", security_severity="7.5")])
        out = ss.summarise_rollup(self.tmp, "nightly", "critical,high")
        self.assertIn("| **Total** | 1 | 1 | 0 | 0 | **2** |", out)

    def test_clean_run_says_nothing_actionable(self):
        self.write("a", [], [])
        out = ss.summarise_rollup(self.tmp, "nightly", "critical,high")
        self.assertIn("Nothing critical or high", out)

    def test_points_maintainers_at_the_shared_base_layer(self):
        self.write("a", [result("CVE-2026-1")], [rule("CVE-2026-1", security_severity="9.8")])
        out = ss.summarise_rollup(self.tmp, "nightly", "critical,high")
        self.assertIn("base", out)
        self.assertIn("node-base", out)

    def test_an_unreadable_report_does_not_lose_the_others(self):
        self.write("good", [result("CVE-2026-1")], [rule("CVE-2026-1", security_severity="9.8")])
        bad = self.tmp / "scout-bad"
        bad.mkdir()
        (bad / "scout-bad.sarif").write_text("{not json")
        out = ss.summarise_rollup(self.tmp, "nightly", "critical,high")
        self.assertIn("`good`", out)
        self.assertIn("Could not read", out)
