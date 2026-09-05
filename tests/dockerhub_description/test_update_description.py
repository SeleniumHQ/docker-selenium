import importlib.util
import pathlib
import tempfile
import unittest

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "dockerhub_description" / "update_description.py"
spec = importlib.util.spec_from_file_location("update_description", MODULE_PATH)
ud = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ud)

FOOTER = "## License\n\nApache 2.0.\n"


class TempDirTestCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp_path = pathlib.Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def write(self, name, text):
        path = self.tmp_path / name
        path.write_text(text)
        return path


class ParseDescriptionTest(TempDirTestCase):
    def test_reads_short_description_and_body(self):
        path = self.write("hub.md", "---\ndescription: Selenium Grid in Hub mode\n---\n# Hub\n\nBody text.\n")
        desc = ud.parse_description(path, FOOTER)
        self.assertEqual(desc.name, "hub")
        self.assertEqual(desc.short, "Selenium Grid in Hub mode")
        self.assertTrue(desc.full.startswith("# Hub"))

    def test_appends_footer_exactly_once(self):
        path = self.write("hub.md", "---\ndescription: Hub\n---\n# Hub\n")
        desc = ud.parse_description(path, FOOTER)
        self.assertEqual(desc.full.count("## License"), 1)
        self.assertTrue(desc.full.rstrip().endswith(FOOTER.rstrip()))

    def test_honours_footer_false(self):
        path = self.write("keda.md", "---\ndescription: KEDA\nfooter: false\n---\n# KEDA\n")
        desc = ud.parse_description(path, FOOTER)
        self.assertNotIn("## License", desc.full)
        self.assertEqual(desc.full.rstrip(), "# KEDA")

    def test_rejects_missing_frontmatter(self):
        path = self.write("hub.md", "# Hub\n\nNo frontmatter here.\n")
        with self.assertRaisesRegex(ValueError, "frontmatter"):
            ud.parse_description(path, FOOTER)

    def test_rejects_empty_description_key(self):
        path = self.write("hub.md", "---\ndescription:\n---\n# Hub\n")
        with self.assertRaisesRegex(ValueError, "description"):
            ud.parse_description(path, FOOTER)


class ValidateTest(unittest.TestCase):
    def test_accepts_a_good_description(self):
        desc = ud.Description(name="hub", short="Selenium Grid in Hub mode", full="# Hub\n")
        self.assertEqual(ud.validate(desc), [])

    def test_rejects_short_description_over_100_chars(self):
        desc = ud.Description(name="hub", short="x" * 101, full="# Hub\n")
        problems = ud.validate(desc)
        self.assertEqual(len(problems), 1)
        self.assertIn("100", problems[0])

    def test_accepts_short_description_of_exactly_100_chars(self):
        desc = ud.Description(name="hub", short="x" * 100, full="# Hub\n")
        self.assertEqual(ud.validate(desc), [])

    def test_rejects_full_description_over_25000_chars(self):
        desc = ud.Description(name="hub", short="Hub", full="x" * 25_001)
        problems = ud.validate(desc)
        self.assertEqual(len(problems), 1)
        self.assertIn("25000", problems[0])

    def test_rejects_empty_full_description(self):
        desc = ud.Description(name="hub", short="Hub", full="   \n  ")
        problems = ud.validate(desc)
        self.assertEqual(len(problems), 1)
        self.assertIn("empty", problems[0])
