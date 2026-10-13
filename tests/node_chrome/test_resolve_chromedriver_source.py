"""Tests for NodeChrome/resolve-chromedriver-source.sh.

This is the decision that took the nightly down for six nights: which archive a
ChromeDriver comes from on a given architecture. It is exercised as a script - through
subprocess, with a stubbed ``wget`` on ``PATH`` - rather than reimplemented in Python.

The stub answers two kinds of request:
  * ``LATEST_RELEASE_<major>`` -> the version in STUB_LATEST, or 404 when unset
  * ``--spider`` on a chromedriver zip -> 0 when the URL's platform is in STUB_PLATFORMS
"""

import os
import pathlib
import stat
import subprocess
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).parents[2] / "NodeChrome" / "resolve-chromedriver-source.sh"

WGET_STUB = r"""#!/bin/sh
# Emulate the two Chrome for Testing endpoints the resolver touches.
for arg in "$@"; do
  case "${arg}" in
    *LATEST_RELEASE_*)
      [ -n "${STUB_LATEST:-}" ] || exit 8
      printf '%s' "${STUB_LATEST}"
      exit 0
      ;;
    *chromedriver-*.zip)
      platform=$(basename "${arg}" .zip | sed 's/^chromedriver-//')
      case " ${STUB_PLATFORMS:-} " in
        *" ${platform} "*) exit 0 ;;
        *) exit 8 ;;
      esac
      ;;
  esac
done
exit 0
"""


class ResolveChromedriverSourceTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.bin = pathlib.Path(self._tmp.name) / "bin"
        self.bin.mkdir()
        stub = self.bin / "wget"
        stub.write_text(WGET_STUB)
        stub.chmod(stub.stat().st_mode | stat.S_IEXEC)

    def run_script(self, arch, major, version="", latest=None, platforms="linux64 linux-arm64"):
        env = dict(os.environ)
        env["PATH"] = f"{self.bin}{os.pathsep}{env['PATH']}"
        env["STUB_PLATFORMS"] = platforms
        if latest is not None:
            env["STUB_LATEST"] = latest
        else:
            env.pop("STUB_LATEST", None)
        return subprocess.run(
            ["bash", str(SCRIPT), arch, major, version],
            capture_output=True,
            text=True,
            env=env,
        )

    def test_amd64_uses_chrome_for_testing(self):
        result = self.run_script("amd64", "153", latest="153.0.8010.36")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.split(), ["cft", "linux64", "153.0.8010.36"])

    def test_arm64_uses_chrome_for_testing_when_it_publishes_one(self):
        # The live case as of 2026-09-14: CfT ships linux-arm64 from Chrome 153.
        result = self.run_script("arm64", "153", latest="153.0.8010.36")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.split(), ["cft", "linux-arm64", "153.0.8010.36"])

    def test_arm64_falls_back_when_chrome_for_testing_has_no_arm64_build(self):
        # Chrome 152 and earlier: linux64 only, so the Debian chromium-driver archive
        # is still the only source.
        result = self.run_script("arm64", "152", latest="152.0.7977.82", platforms="linux64")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "chromium-package")

    def test_amd64_never_falls_back(self):
        # Google has always published linux64. If the probe says otherwise something is
        # wrong with the network, and silently switching amd64 to a third-party Debian
        # archive would be a far worse outcome than failing.
        result = self.run_script("amd64", "153", latest="153.0.8010.36", platforms="")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "")

    def test_explicit_version_is_honoured_and_not_looked_up(self):
        result = self.run_script("arm64", "153", version="153.0.8010.36", latest=None)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.split(), ["cft", "linux-arm64", "153.0.8010.36"])

    def test_unknown_architecture_uses_the_chromium_package(self):
        result = self.run_script("ppc64el", "153", latest="153.0.8010.36")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "chromium-package")

    def test_arm64_falls_back_when_the_version_lookup_fails(self):
        result = self.run_script("arm64", "153", latest=None)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "chromium-package")


if __name__ == "__main__":
    unittest.main()
