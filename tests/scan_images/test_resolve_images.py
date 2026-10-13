import contextlib
import importlib.util
import io
import pathlib
import unittest
import urllib.error

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "scan_images" / "resolve_images.py"
spec = importlib.util.spec_from_file_location("resolve_images", MODULE_PATH)
ri = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ri)

MAKEFILE = """
tag_latest:
\tdocker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:latest
\tdocker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:latest
\tdocker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:latest

tag_ffmpeg_latest:
\tdocker tag $(NAME)/ffmpeg:$(FFMPEG_TAG_VERSION) $(NAME)/ffmpeg:latest

release_grid_scaler_latest:
\tdocker buildx imagetools create -t $(NAME)/keda:latest upstream/keda:1
\tdocker buildx imagetools create -t $(NAME)/keda-metrics-apiserver:latest upstream/x:1
\tdocker buildx imagetools create -t $(NAME)/keda-admission-webhooks:latest upstream/y:1

tag_nightly:
\tdocker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:nightly
\tdocker tag $(NAME)/keda-external-scaler:$(TAG_VERSION) $(NAME)/keda-external-scaler:nightly
"""


class ImagesForTagTest(unittest.TestCase):
    def test_collects_every_image_published_under_the_tag(self):
        self.assertEqual(ri.images_for_tag(MAKEFILE, "latest"), ["base", "ffmpeg", "hub", "node-chrome"])

    def test_excludes_the_upstream_keda_mirrors(self):
        found = ri.images_for_tag(MAKEFILE, "latest")
        for mirror in ["keda", "keda-metrics-apiserver", "keda-admission-webhooks"]:
            self.assertNotIn(mirror, found)

    def test_keeps_keda_external_scaler_which_is_ours(self):
        self.assertIn("keda-external-scaler", ri.images_for_tag(MAKEFILE, "nightly"))

    def test_a_different_tag_gets_a_different_list(self):
        self.assertEqual(ri.images_for_tag(MAKEFILE, "nightly"), ["base", "keda-external-scaler"])

    def test_unknown_tag_is_empty_rather_than_everything(self):
        self.assertEqual(ri.images_for_tag(MAKEFILE, "beta"), [])

    def test_tag_match_does_not_run_past_the_tag(self):
        # ':latest' must not also match ':latest-arm64'
        text = "\t$(NAME)/base:latest-arm64\n\t$(NAME)/hub:latest\n"
        self.assertEqual(ri.images_for_tag(text, "latest"), ["hub"])

    def test_this_is_the_bug_the_shell_version_had(self):
        # The shell built its pattern in double quotes, so bash turned '\$' into a
        # bare '$' and grep read it as an end-of-line anchor: zero matches, and a
        # green run that scanned nothing. Guard the real Makefile, not a fixture.
        real = (pathlib.Path(__file__).parents[2] / "Makefile").read_text()
        self.assertGreater(len(ri.images_for_tag(real, "latest")), 20)
        self.assertGreater(len(ri.images_for_tag(real, "nightly")), 20)


class StubOpener:
    """Stands in for urllib.request.urlopen. `missing` 404s, `broken` raises."""

    def __init__(self, missing=(), broken=()):
        self.missing = set(missing)
        self.broken = set(broken)
        self.calls = []

    def __call__(self, url, timeout=None):
        self.calls.append(url)
        image = url.rstrip("/").split("/")[-3]
        if image in self.broken:
            raise urllib.error.URLError("connection reset")
        if image in self.missing:
            raise urllib.error.HTTPError(url, 404, "Not Found", {}, io.BytesIO(b""))
        return object()


class VerifyTest(unittest.TestCase):
    def test_splits_published_from_missing(self):
        opener = StubOpener(missing={"ffmpeg"})
        published, missing = ri.verify(["base", "ffmpeg", "hub"], "selenium", "nightly", opener)
        self.assertEqual(published, ["base", "hub"])
        self.assertEqual(missing, ["ffmpeg"])

    def test_all_present_means_nothing_missing(self):
        published, missing = ri.verify(["base", "hub"], "selenium", "latest", StubOpener())
        self.assertEqual(published, ["base", "hub"])
        self.assertEqual(missing, [])

    def test_a_registry_error_keeps_the_image_rather_than_emptying_the_matrix(self):
        opener = StubOpener(broken={"hub"})
        with contextlib.redirect_stderr(io.StringIO()):
            published, missing = ri.verify(["base", "hub"], "selenium", "latest", opener)
        self.assertEqual(published, ["base", "hub"])
        self.assertEqual(missing, [])

    def test_checks_the_requested_tag(self):
        opener = StubOpener()
        ri.verify(["base"], "selenium", "nightly", opener)
        self.assertTrue(opener.calls[0].endswith("/repositories/selenium/base/tags/nightly/"))


class TagExistsTest(unittest.TestCase):
    def test_true_when_present(self):
        self.assertTrue(ri.tag_exists("selenium", "base", "latest", StubOpener()))

    def test_false_on_404(self):
        self.assertFalse(ri.tag_exists("selenium", "base", "latest", StubOpener(missing={"base"})))

    def test_non_404_http_errors_propagate(self):
        def opener(url, timeout=None):
            raise urllib.error.HTTPError(url, 500, "Server Error", {}, io.BytesIO(b""))

        with self.assertRaises(urllib.error.HTTPError):
            ri.tag_exists("selenium", "base", "latest", opener)


class MainTest(unittest.TestCase):
    def test_explicit_images_override_the_makefile(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
            code = ri.main(["--tag", "latest", "--images", "hub, base"])
        self.assertEqual(code, 0)
        self.assertEqual(out.getvalue().strip(), '["base", "hub"]')

    def test_unknown_tag_exits_non_zero_rather_than_emitting_an_empty_matrix(self):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(ri.main(["--tag", "no-such-tag"]), 1)
