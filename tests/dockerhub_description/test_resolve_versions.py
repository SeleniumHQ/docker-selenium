import importlib.util
import pathlib
import tempfile
import unittest

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "dockerhub_description" / "resolve_versions.py"
spec = importlib.util.spec_from_file_location("resolve_versions", MODULE_PATH)
rv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rv)

CHROME = """```
./tag_and_push_browser_images.sh 4.48.0 20260909 selenium false chrome true
Selenium Grid version -> 4.48.0-20260909
Chrome version -> 152.0.7977.82
Short Chrome version -> 152.0
ChromeDriver version -> 152.0.7977.82
Short ChromeDriver version -> 152.0
```
"""

FIREFOX = """```
Selenium Grid version -> 4.48.0-20260909
Short Firefox version -> 155.0
Short GeckoDriver version -> 0.37
```
"""

EDGE = """```
Selenium Grid version -> 4.48.0-20260909
Short Edge version -> 152.0
Short EdgeDriver version -> 152.0
```
"""

CFT = """```
Selenium Grid version -> 4.48.0-20260909
Short Chrome for Testing version -> 152.0
Short ChromeDriver version -> 152.0
```
"""


class ChangelogTestCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def changelog(self, version="4.48.0", entries=None):
        entries = (
            entries
            if entries is not None
            else {
                "chrome_152.md": CHROME,
                "chrome-for-testing_152.md": CFT,
                "edge_152.md": EDGE,
                "firefox_155.md": FIREFOX,
            }
        )
        d = self.root / version
        d.mkdir(parents=True)
        for name, body in entries.items():
            (d / name).write_text(body)
        return self.root


class LatestReleaseDirTest(ChangelogTestCase):
    def test_picks_the_highest_version_not_the_alphabetical_one(self):
        for v in ["4.9.0", "4.48.0", "4.10.0"]:
            (self.root / v).mkdir(parents=True)
        self.assertEqual(rv.latest_release_dir(self.root).name, "4.48.0")

    def test_ignores_non_release_directories(self):
        (self.root / "4.48.0").mkdir()
        (self.root / "archived").mkdir()
        self.assertEqual(rv.latest_release_dir(self.root).name, "4.48.0")

    def test_raises_when_there_is_no_release_directory(self):
        (self.root / "archived").mkdir()
        with self.assertRaisesRegex(RuntimeError, "no CHANGELOG"):
            rv.latest_release_dir(self.root)


class NewestChangelogTest(ChangelogTestCase):
    def test_picks_the_highest_browser_major(self):
        d = self.root / "4.48.0"
        d.mkdir()
        for major in ["9", "152", "100"]:
            (d / f"chrome_{major}.md").write_text(CHROME)
        self.assertEqual(rv.newest_changelog(d, "chrome").name, "chrome_152.md")

    def test_chrome_prefix_does_not_match_chrome_for_testing(self):
        d = self.root / "4.48.0"
        d.mkdir()
        (d / "chrome-for-testing_152.md").write_text(CFT)
        self.assertIsNone(rv.newest_changelog(d, "chrome"))

    def test_returns_none_when_absent(self):
        d = self.root / "4.48.0"
        d.mkdir()
        self.assertIsNone(rv.newest_changelog(d, "firefox"))


class ParseChangelogTest(ChangelogTestCase):
    def test_reads_short_versions_and_the_grid_tag(self):
        d = self.root / "4.48.0"
        d.mkdir()
        path = d / "chrome_152.md"
        path.write_text(CHROME)
        fields = rv.parse_changelog(path)
        self.assertEqual(fields["Chrome"], "152.0")
        self.assertEqual(fields["ChromeDriver"], "152.0")
        self.assertEqual(fields["grid_tag"], "4.48.0-20260909")

    def test_prefers_the_short_version_over_the_full_one(self):
        fields = rv.parse_changelog(self._write(CHROME))
        self.assertEqual(fields["Chrome"], "152.0")
        self.assertNotEqual(fields["Chrome"], "152.0.7977.82")

    def _write(self, body):
        d = self.root / "4.48.0"
        d.mkdir(exist_ok=True)
        path = d / "chrome_152.md"
        path.write_text(body)
        return path


class ResolveTest(ChangelogTestCase):
    def test_resolves_grid_and_every_changelog_browser(self):
        resolved, problems = rv.resolve(self.changelog(), "selenium", skip_chromium=True)
        self.assertEqual(problems, [])
        self.assertEqual(resolved["release"], "4.48.0")
        self.assertEqual(
            resolved["grid"],
            {
                "tag": "4.48.0-20260909",
                "version": "4.48.0",
                "date": "20260909",
                "major": "4",
                "major_minor": "4.48",
                "patch": "0",
            },
        )
        self.assertEqual(sorted(resolved["browsers"]), ["chrome", "chrome-for-testing", "edge", "firefox"])
        self.assertEqual(resolved["browsers"]["firefox"], {"browser": "155.0", "driver": "0.37"})

    def test_grid_tag_override_wins_over_the_changelog(self):
        resolved, _ = rv.resolve(self.changelog(), "selenium", skip_chromium=True, grid_tag_override="4.49.0-20261010")
        self.assertEqual(resolved["grid"]["version"], "4.49.0")
        self.assertEqual(resolved["grid"]["major_minor"], "4.49")
        self.assertEqual(resolved["grid"]["date"], "20261010")

    def test_missing_browser_changelog_is_reported_without_aborting(self):
        root = self.changelog(entries={"chrome_152.md": CHROME})
        resolved, problems = rv.resolve(root, "selenium", skip_chromium=True)
        self.assertIsNotNone(resolved)
        self.assertEqual(sorted(resolved["browsers"]), ["chrome"])
        self.assertEqual(len(problems), 3)
        self.assertTrue(all("no " in p for p in problems))

    def test_changelog_without_a_grid_line_fails(self):
        root = self.changelog(
            entries={"chrome_152.md": "```\nShort Chrome version -> 152.0\nShort ChromeDriver version -> 152.0\n```\n"}
        )
        resolved, problems = rv.resolve(root, "selenium", skip_chromium=True)
        self.assertIsNone(resolved)
        self.assertTrue(any("Selenium Grid version" in p for p in problems))
