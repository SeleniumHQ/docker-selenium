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


MAKEFILE_SNIPPET = """
hub: base
\tcd ./Hub && docker buildx build -t $(NAME)/hub:$(TAG_VERSION) .

video: base
\tcd ./Video && docker buildx build -t $(NAME)/video:$(FFMPEG_TAG_VERSION) .

keda:
\tdocker buildx imagetools create -t $(NAME)/keda:latest upstream/keda:1
"""


class DriftTest(TempDirTestCase):
    def makefile(self):
        path = self.tmp_path / "Makefile"
        path.write_text(MAKEFILE_SNIPPET)
        return path

    def docs(self, names):
        docs = self.tmp_path / "docs"
        docs.mkdir()
        (docs / "_footer.md").write_text(FOOTER)
        (docs / "README.md").write_text("# How to edit these\n")
        for name in names:
            (docs / f"{name}.md").write_text(f"---\ndescription: {name}\n---\n# {name}\n")
        return docs

    def test_image_names_parsed_from_makefile(self):
        self.assertEqual(ud.image_names_from_makefile(self.makefile()), {"hub", "video", "keda"})

    def test_description_files_skips_readme_and_underscore(self):
        docs = self.docs(["hub", "video"])
        self.assertEqual([p.stem for p in ud.description_files(docs)], ["hub", "video"])

    def test_passes_when_sets_match(self):
        self.assertEqual(ud.check_drift(self.docs(["hub", "video", "keda"]), self.makefile()), [])

    def test_reports_image_without_description_file(self):
        problems = ud.check_drift(self.docs(["hub", "video"]), self.makefile())
        self.assertEqual(len(problems), 1)
        self.assertIn("keda", problems[0])
        self.assertIn("docs/docker-hub/keda.md", problems[0])

    def test_reports_orphan_description_file(self):
        problems = ud.check_drift(self.docs(["hub", "video", "keda", "retired-image"]), self.makefile())
        self.assertEqual(len(problems), 1)
        self.assertIn("retired-image", problems[0])

    def test_reports_both_directions_at_once(self):
        # keda and video are built but undocumented; retired-image is documented but not built.
        problems = ud.check_drift(self.docs(["hub", "retired-image"]), self.makefile())
        self.assertEqual(len(problems), 3)
        self.assertEqual(sum("built by the Makefile" in p for p in problems), 2)
        self.assertEqual(sum("no $(NAME)/" in p for p in problems), 1)


class StubClient:
    def __init__(self, remote, fail=()):
        self.remote = remote
        self.fail = set(fail)
        self.patched = []

    def get(self, name):
        if name in self.fail:
            raise RuntimeError("boom")
        return self.remote.get(name, {"description": "", "full_description": ""})

    def patch(self, name, short, full):
        self.patched.append((name, short, full))


class NeedsUpdateTest(unittest.TestCase):
    def test_false_when_identical(self):
        desc = ud.Description(name="hub", short="Hub", full="# Hub\n")
        self.assertFalse(ud.needs_update(desc, {"description": "Hub", "full_description": "# Hub\n"}))

    def test_false_when_only_trailing_whitespace_differs(self):
        desc = ud.Description(name="hub", short="Hub", full="# Hub\n")
        self.assertFalse(ud.needs_update(desc, {"description": "Hub", "full_description": "# Hub\n\n\n"}))

    def test_true_when_short_description_differs(self):
        desc = ud.Description(name="hub", short="Hub v2", full="# Hub\n")
        self.assertTrue(ud.needs_update(desc, {"description": "Hub", "full_description": "# Hub\n"}))

    def test_true_when_body_differs(self):
        desc = ud.Description(name="hub", short="Hub", full="# Hub v2\n")
        self.assertTrue(ud.needs_update(desc, {"description": "Hub", "full_description": "# Hub\n"}))

    def test_true_when_remote_is_empty(self):
        desc = ud.Description(name="keda-external-scaler", short="Scaler", full="# Scaler\n")
        self.assertTrue(ud.needs_update(desc, {"description": "", "full_description": ""}))


class SyncTest(unittest.TestCase):
    def test_patches_only_changed_repositories(self):
        descs = [
            ud.Description(name="hub", short="Hub", full="# Hub\n"),
            ud.Description(name="video", short="Video v2", full="# Video\n"),
        ]
        client = StubClient(
            {
                "hub": {"description": "Hub", "full_description": "# Hub\n"},
                "video": {"description": "Video", "full_description": "# Video\n"},
            }
        )
        self.assertEqual(ud.sync(descs, client, dry_run=False), (1, 0))
        self.assertEqual([name for name, _, _ in client.patched], ["video"])

    def test_dry_run_never_patches(self):
        descs = [ud.Description(name="video", short="Video v2", full="# Video\n")]
        client = StubClient({"video": {"description": "Video", "full_description": "# Video\n"}})
        self.assertEqual(ud.sync(descs, client, dry_run=True), (1, 0))
        self.assertEqual(client.patched, [])

    def test_continues_past_a_failing_repository(self):
        descs = [
            ud.Description(name="broken", short="Broken", full="# Broken\n"),
            ud.Description(name="video", short="Video v2", full="# Video\n"),
        ]
        client = StubClient({"video": {"description": "Video", "full_description": "# Video\n"}}, fail=["broken"])
        self.assertEqual(ud.sync(descs, client, dry_run=False), (1, 1))
        self.assertEqual([name for name, _, _ in client.patched], ["video"])


class LoadAllTest(TempDirTestCase):
    def makefile(self):
        path = self.tmp_path / "Makefile"
        path.write_text(MAKEFILE_SNIPPET)
        return path

    def docs(self, names, footer=True):
        docs = self.tmp_path / "docs"
        docs.mkdir()
        if footer:
            (docs / "_footer.md").write_text(FOOTER)
        for name in names:
            (docs / f"{name}.md").write_text(f"---\ndescription: {name}\n---\n# {name}\n")
        return docs

    def test_reports_a_missing_footer_file(self):
        docs = self.docs(["hub", "video", "keda"], footer=False)
        descs, problems = ud._load_all(docs, self.makefile(), set())
        self.assertEqual(len(problems), 1)
        self.assertIn("_footer.md", problems[0])
        self.assertEqual(len(descs), 3)

    def test_present_footer_is_applied_and_reports_no_problem(self):
        docs = self.docs(["hub", "video", "keda"])
        descs, problems = ud._load_all(docs, self.makefile(), set())
        self.assertEqual(problems, [])
        self.assertTrue(all("## License" in d.full for d in descs))

    def test_reports_an_unmatched_repo_filter(self):
        docs = self.docs(["hub", "video", "keda"])
        descs, problems = ud._load_all(docs, self.makefile(), {"hubb"})
        self.assertEqual(len(problems), 1)
        self.assertIn("--repo", problems[0])
        self.assertIn("hubb", problems[0])
        self.assertEqual(descs, [])

    def test_a_matched_repo_filter_loads_only_that_repository(self):
        docs = self.docs(["hub", "video", "keda"])
        descs, problems = ud._load_all(docs, self.makefile(), {"hub"})
        self.assertEqual(problems, [])
        self.assertEqual([d.name for d in descs], ["hub"])
