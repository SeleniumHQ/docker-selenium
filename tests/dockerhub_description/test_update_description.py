import contextlib
import importlib.util
import io
import json
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
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ud.sync(descs, client, dry_run=False), (1, 0))
        self.assertEqual([name for name, _, _ in client.patched], ["video"])

    def test_dry_run_never_patches(self):
        descs = [ud.Description(name="video", short="Video v2", full="# Video\n")]
        client = StubClient({"video": {"description": "Video", "full_description": "# Video\n"}})
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ud.sync(descs, client, dry_run=True), (1, 0))
        self.assertEqual(client.patched, [])

    def test_continues_past_a_failing_repository(self):
        descs = [
            ud.Description(name="broken", short="Broken", full="# Broken\n"),
            ud.Description(name="video", short="Video v2", full="# Video\n"),
        ]
        client = StubClient({"video": {"description": "Video", "full_description": "# Video\n"}}, fail=["broken"])
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ud.sync(descs, client, dry_run=False), (1, 1))
        self.assertEqual([name for name, _, _ in client.patched], ["video"])


VERSIONS = {
    "grid": {
        "tag": "4.48.0-20260909",
        "version": "4.48.0",
        "date": "20260909",
        "major": "4",
        "major_minor": "4.48",
        "patch": "0",
    },
    "browsers": {
        "chrome": {"browser": "152.0", "driver": "152.0"},
        "chrome-for-testing": {"browser": "152.0", "driver": "152.0"},
        "firefox": {"browser": "155.0", "driver": "0.37"},
        "chromium": {
            "browser": "152.0",
            "driver": "152.0",
            "browser_full": "152.0.7977.75",
            "driver_full": "152.0.7977.75",
        },
    },
}


class LoadAllTest(TempDirTestCase):
    def makefile(self):
        path = self.tmp_path / "Makefile"
        path.write_text(MAKEFILE_SNIPPET)
        return path

    def docs(self, names, footer=True, versions=True):
        docs = self.tmp_path / "docs"
        docs.mkdir()
        if footer:
            (docs / "_footer.md").write_text(FOOTER)
        if versions:
            (docs / "_versions.json").write_text(json.dumps(VERSIONS))
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


GRID_BLOCK = """# Hub

### Example of a release with Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>
e126989f151e        selenium/hub   <Major>
e126989f151e        selenium/hub   <Major>.<Minor>
e126989f151e        selenium/hub   <Major>.<Minor>.<Patch>
e126989f151e        selenium/hub   <Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Trailing prose with <Major> left alone.
"""


class BrowserKeyTest(unittest.TestCase):
    def test_maps_node_and_standalone_to_the_same_browser(self):
        self.assertEqual(ud.browser_key("node-chrome"), "chrome")
        self.assertEqual(ud.browser_key("standalone-chrome"), "chrome")

    def test_chrome_for_testing_is_not_matched_as_chrome(self):
        self.assertEqual(ud.browser_key("node-chrome-for-testing"), "chrome-for-testing")
        self.assertEqual(ud.browser_key("standalone-chrome-for-testing"), "chrome-for-testing")

    def test_grid_only_images_have_no_browser(self):
        for name in ["hub", "distributor", "router", "video", "node-docker", "standalone-kubernetes"]:
            self.assertIsNone(ud.browser_key(name), name)


class ExampleSpanTest(unittest.TestCase):
    def test_returns_none_when_there_is_no_example_block(self):
        self.assertIsNone(ud.example_span("# Hub\n\nNo example here.\n"))

    def test_span_covers_heading_through_closing_fence(self):
        start, end = ud.example_span(GRID_BLOCK)
        block = GRID_BLOCK[start:end]
        self.assertTrue(block.startswith("### Example of a release"))
        self.assertTrue(block.rstrip().endswith("```"))


class SubstituteExampleTest(unittest.TestCase):
    def test_grid_tokens_are_replaced_longest_first(self):
        out, problems = ud.substitute_example(GRID_BLOCK, VERSIONS, "hub")
        self.assertEqual(problems, [])
        self.assertIn("selenium/hub   4.48.0-20260909", out)
        self.assertIn("selenium/hub   4.48.0\n", out)
        self.assertIn("selenium/hub   4.48\n", out)
        self.assertIn("selenium/hub   4\n", out)
        self.assertIn("Selenium Grid Server 4.48.0, released on 20260909", out)

    def test_nothing_outside_the_block_is_touched(self):
        out, _ = ud.substitute_example(GRID_BLOCK, VERSIONS, "hub")
        self.assertIn("Trailing prose with <Major> left alone.", out)

    def test_browser_tokens_use_the_matching_entry(self):
        text = GRID_BLOCK.replace("selenium/hub   <Major>\n", "selenium/x   <BrowserMajor>.<BrowserMinor>\n")
        text = text.replace(
            "Selenium Server",
            "Firefox <BrowserMajor>, GeckoDriver <GeckoDriverMajor>.<GeckoDriverMinor>\n    Selenium Server",
            1,
        )
        out, problems = ud.substitute_example(text, VERSIONS, "standalone-firefox")
        self.assertEqual(problems, [])
        self.assertIn("selenium/x   155.0", out)
        self.assertIn("Firefox 155, GeckoDriver 0.37", out)

    def test_chromium_full_version_tokens_are_replaced(self):
        text = GRID_BLOCK.replace(
            "selenium/hub   <Major>\n", "selenium/x   <BrowserFullVersion>-chromedriver-<DriverFullVersion>\n"
        )
        out, problems = ud.substitute_example(text, VERSIONS, "standalone-chromium")
        self.assertEqual(problems, [])
        self.assertIn("152.0.7977.75-chromedriver-152.0.7977.75", out)

    def test_missing_browser_entry_is_reported(self):
        out, problems = ud.substitute_example(GRID_BLOCK, VERSIONS, "standalone-edge")
        self.assertEqual(len(problems), 1)
        self.assertIn("no browser entry", problems[0])
        self.assertEqual(out, GRID_BLOCK)

    def test_unresolved_placeholder_is_reported(self):
        text = GRID_BLOCK.replace("selenium/hub   <Major>\n", "selenium/hub   <Unknown>\n")
        _, problems = ud.substitute_example(text, VERSIONS, "hub")
        self.assertEqual(len(problems), 1)
        self.assertIn("<Unknown>", problems[0])

    def test_no_versions_leaves_text_untouched(self):
        out, problems = ud.substitute_example(GRID_BLOCK, None, "hub")
        self.assertEqual(out, GRID_BLOCK)
        self.assertEqual(problems, [])

    def test_text_without_an_example_block_is_untouched(self):
        text = "# Hub\n\nNothing to substitute.\n"
        out, problems = ud.substitute_example(text, VERSIONS, "hub")
        self.assertEqual(out, text)
        self.assertEqual(problems, [])


class MissingVersionsTest(TempDirTestCase):
    def test_missing_versions_file_is_reported(self):
        docs = self.tmp_path / "docs"
        docs.mkdir()
        (docs / "_footer.md").write_text(FOOTER)
        for name in ["hub", "video", "keda"]:
            (docs / f"{name}.md").write_text(f"---\ndescription: {name}\n---\n# {name}\n")
        makefile = self.tmp_path / "Makefile"
        makefile.write_text(MAKEFILE_SNIPPET)
        _, problems = ud._load_all(docs, makefile, set())
        self.assertEqual(len(problems), 1)
        self.assertIn("_versions.json", problems[0])
