import importlib.util
import io
import json
import pathlib
import tempfile
import unittest
from contextlib import redirect_stdout

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "ci" / "new_scan_findings.py"
spec = importlib.util.spec_from_file_location("new_scan_findings", MODULE_PATH)
nsf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nsf)


def result(rule, uri, message, line=1):
    return {
        "ruleId": rule,
        "message": {"text": message},
        "locations": [{"physicalLocation": {"artifactLocation": {"uri": uri}, "region": {"startLine": line}}}],
    }


class NewScanFindingsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)

    def sarif(self, name, results):
        path = pathlib.Path(self.tmp.name) / name
        path.write_text(json.dumps({"runs": [{"results": results}]}))
        return str(path)

    def run_main(self, base, head):
        out = io.StringIO()
        with redirect_stdout(out):
            code = nsf.main(["new_scan_findings.py", base, head])
        return code, out.getvalue()

    def test_same_findings_pass(self):
        findings = [result("DS-0031", "Base/Dockerfile", "secret in ENV"), result("KSV-0014", "a.yaml", "rw root")]
        code, out = self.run_main(self.sarif("base", findings), self.sarif("head", findings))
        self.assertEqual(code, 0)
        self.assertIn("No new findings", out)

    def test_moved_finding_is_not_new(self):
        base = self.sarif("base", [result("DS-0031", "Base/Dockerfile", "secret in ENV", line=208)])
        head = self.sarif("head", [result("DS-0031", "Base/Dockerfile", "secret in ENV", line=212)])
        self.assertEqual(self.run_main(base, head)[0], 0)

    def test_new_finding_fails(self):
        base = self.sarif("base", [result("KSV-0014", "a.yaml", "rw root")])
        head = self.sarif(
            "head", [result("KSV-0014", "a.yaml", "rw root"), result("private-key", "certs/new.key", "Private key")]
        )
        code, out = self.run_main(base, head)
        self.assertEqual(code, 1)
        self.assertIn("private-key in certs/new.key: Private key", out)

    def test_extra_copy_of_existing_finding_fails(self):
        finding = result("KSV-0118", "a.yaml", "default security context")
        code, out = self.run_main(self.sarif("base", [finding]), self.sarif("head", [finding, finding]))
        self.assertEqual(code, 1)
        self.assertIn("1 new finding(s)", out)

    def test_removed_finding_passes(self):
        base = self.sarif("base", [result("KSV-0014", "a.yaml", "rw root")])
        self.assertEqual(self.run_main(base, self.sarif("head", []))[0], 0)


if __name__ == "__main__":
    unittest.main()
