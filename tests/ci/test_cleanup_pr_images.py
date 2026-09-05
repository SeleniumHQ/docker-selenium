import importlib.util
import pathlib
import unittest

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "ci" / "cleanup_pr_images.py"
spec = importlib.util.spec_from_file_location("cleanup_pr_images", MODULE_PATH)
cp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cp)


def version(vid, tags):
    return {"id": vid, "metadata": {"container": {"tags": tags}}}


def decide(versions, closed, target_pr=None):
    """Mirror of the deletion rule in main(), so it can be exercised without HTTP."""
    main_ids = {v["id"] for v in versions if cp.MAIN_TAG in v["metadata"]["container"]["tags"]}
    out = []
    for v in versions:
        tags = v["metadata"]["container"]["tags"]
        pr_tags = [t for t in tags if cp.PR_TAG.match(t)]
        if not pr_tags:
            continue
        numbers = sorted(int(cp.PR_TAG.match(t).group(1)) for t in pr_tags)
        if target_pr is not None and target_pr not in numbers:
            continue
        if any(not (cp.PR_TAG.match(t) or cp.SRC_TAG.match(t)) for t in tags):
            continue
        if v["id"] in main_ids:
            continue
        if any(n not in closed for n in numbers):
            continue
        out.append(v["id"])
    return out


class DeletionRuleTest(unittest.TestCase):
    def test_deletes_a_closed_pull_requests_images(self):
        vs = [version(1, ["src-aaaaaa", "pr-100"])]
        self.assertEqual(decide(vs, closed={100}), [1])

    def test_keeps_an_open_pull_requests_images(self):
        vs = [version(1, ["src-aaaaaa", "pr-100"])]
        self.assertEqual(decide(vs, closed=set()), [])

    def test_keeps_a_manifest_two_pull_requests_share_when_one_is_open(self):
        # identical image content is one manifest, tagged for both
        vs = [version(1, ["src-aaaaaa", "pr-100", "pr-101"])]
        self.assertEqual(decide(vs, closed={100}), [])

    def test_deletes_a_shared_manifest_once_every_sharer_is_closed(self):
        vs = [version(1, ["src-aaaaaa", "pr-100", "pr-101"])]
        self.assertEqual(decide(vs, closed={100, 101}), [1])

    def test_never_deletes_what_main_points_at(self):
        vs = [version(1, ["src-aaaaaa", "pr-100", "main"])]
        self.assertEqual(decide(vs, closed={100}), [])

    def test_never_deletes_a_release_tag_even_beside_a_pr_tag(self):
        vs = [version(1, ["src-aaaaaa", "pr-100", "4.48.0-20260909"])]
        self.assertEqual(decide(vs, closed={100}), [])

    def test_never_deletes_latest_or_nightly(self):
        for tag in ["latest", "nightly"]:
            vs = [version(1, ["src-aaaaaa", "pr-100", tag])]
            self.assertEqual(decide(vs, closed={100}), [], tag)

    def test_ignores_versions_with_no_pr_tag(self):
        vs = [version(1, ["src-aaaaaa"]), version(2, ["main"])]
        self.assertEqual(decide(vs, closed={100}), [])

    def test_targeting_one_pull_request_leaves_the_others(self):
        vs = [version(1, ["src-aaaaaa", "pr-100"]), version(2, ["src-bbbbbb", "pr-101"])]
        self.assertEqual(decide(vs, closed={100, 101}, target_pr=100), [1])

    def test_main_protection_applies_per_image_not_globally(self):
        vs = [version(1, ["src-aaaaaa", "pr-100", "main"]), version(2, ["src-bbbbbb", "pr-100"])]
        self.assertEqual(decide(vs, closed={100}), [2])
