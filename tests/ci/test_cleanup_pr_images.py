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


def tv(vid, tags, created):
    return {"id": vid, "created_at": created, "metadata": {"container": {"tags": tags}}}


def supersede(versions):
    """Mirror of prune_superseded's rule, exercised without HTTP."""
    main_v = next((v for v in versions if cp.MAIN_TAG in v["metadata"]["container"]["tags"]), None)
    if main_v is None:
        return []
    out = []
    for v in versions:
        tags = v["metadata"]["container"]["tags"]
        if v["id"] == main_v["id"] or not tags:
            continue
        if any(not cp.SRC_TAG.match(t) for t in tags):
            continue
        if not v.get("created_at") or v["created_at"] >= main_v["created_at"]:
            continue
        out.append(v["id"])
    return out


class PruneSupersededTest(unittest.TestCase):
    def test_removes_a_trunk_manifest_older_than_main(self):
        vs = [tv(1, ["src-0d1111"], "2026-09-01"), tv(2, ["src-e42222", "main"], "2026-09-05")]
        self.assertEqual(supersede(vs), [1])

    def test_never_removes_what_main_points_at(self):
        vs = [tv(2, ["src-e42222", "main"], "2026-09-05")]
        self.assertEqual(supersede(vs), [])

    def test_leaves_a_manifest_newer_than_main_alone(self):
        # could be mid-promotion in a concurrent run
        vs = [tv(1, ["src-e4e111"], "2026-09-06"), tv(2, ["src-a11122", "main"], "2026-09-05")]
        self.assertEqual(supersede(vs), [])

    def test_leaves_pull_request_manifests_to_the_other_sweep(self):
        vs = [tv(1, ["src-0d1111", "pr-100"], "2026-09-01"), tv(2, ["src-e42222", "main"], "2026-09-05")]
        self.assertEqual(supersede(vs), [])

    def test_never_removes_a_release_or_floating_tag(self):
        for tag in ["4.48.0-20260909", "latest", "nightly"]:
            vs = [tv(1, ["src-0d1111", tag], "2026-09-01"), tv(2, ["src-e42222", "main"], "2026-09-05")]
            self.assertEqual(supersede(vs), [], tag)

    def test_does_nothing_when_there_is_no_main(self):
        vs = [tv(1, ["src-0d1111"], "2026-09-01")]
        self.assertEqual(supersede(vs), [])

    def test_removes_several_superseded_manifests(self):
        vs = [
            tv(1, ["src-a11111"], "2026-09-01"),
            tv(2, ["src-b22222"], "2026-09-02"),
            tv(3, ["src-c33333", "main"], "2026-09-05"),
        ]
        self.assertEqual(sorted(supersede(vs)), [1, 2])

    def test_skips_an_untagged_manifest(self):
        vs = [tv(1, [], "2026-09-01"), tv(2, ["src-e42222", "main"], "2026-09-05")]
        self.assertEqual(supersede(vs), [])


class SrcTagStrictnessTest(unittest.TestCase):
    def test_matches_a_real_source_hash(self):
        self.assertTrue(cp.SRC_TAG.match("src-331808bba75d"))

    def test_rejects_anything_that_is_not_a_hex_hash(self):
        # a tag merely starting with src- must not be mistaken for one of ours
        for tag in ["src-latest", "src-", "src-release", "srcs-aaaaaa", "src-aaa"]:
            self.assertIsNone(cp.SRC_TAG.match(tag), tag)

    def test_rejects_release_and_floating_tags(self):
        for tag in ["main", "latest", "nightly", "4.48.0-20260909", "ffmpeg-8.1-20260905"]:
            self.assertIsNone(cp.SRC_TAG.match(tag), tag)
            self.assertIsNone(cp.PR_TAG.match(tag), tag)


def orphan(versions, cutoff):
    """Mirror of prune_orphans' rule, exercised without HTTP."""
    out = []
    for v in versions:
        tags = v["metadata"]["container"]["tags"]
        if not tags or any(not cp.SRC_TAG.match(t) for t in tags):
            continue
        created = v.get("created_at") or ""
        if not created or created >= cutoff:
            continue
        out.append(v["id"])
    return out


class PruneOrphansTest(unittest.TestCase):
    """The case a PR with several image-affecting commits leaves behind.

    pr-<N> is retagged onto each new build, so earlier manifests keep only src-*.
    """

    def test_removes_earlier_builds_of_the_same_pull_request(self):
        vs = [
            tv(1, ["src-a11111"], "2026-09-01"),  # commit 1, alias moved away
            tv(2, ["src-b22222"], "2026-09-02"),  # commit 2, alias moved away
            tv(3, ["src-c33333", "pr-100"], "2026-09-03"),  # current build, aliased
        ]
        self.assertEqual(sorted(orphan(vs, cutoff="2026-09-03")), [1, 2])

    def test_never_removes_the_currently_aliased_build(self):
        vs = [tv(3, ["src-c33333", "pr-100"], "2026-09-01")]
        self.assertEqual(orphan(vs, cutoff="2026-09-05"), [])

    def test_never_removes_main_or_a_release_tag(self):
        for tag in ["main", "latest", "nightly", "4.48.0-20260909"]:
            vs = [tv(1, ["src-a11111", tag], "2026-09-01")]
            self.assertEqual(orphan(vs, cutoff="2026-09-05"), [], tag)

    def test_respects_the_age_guard(self):
        # covers the minutes between a manifest being pushed and its alias landing
        vs = [tv(1, ["src-a11111"], "2026-09-05")]
        self.assertEqual(orphan(vs, cutoff="2026-09-01"), [])

    def test_skips_a_manifest_with_no_creation_date(self):
        vs = [{"id": 1, "created_at": None, "metadata": {"container": {"tags": ["src-a11111"]}}}]
        self.assertEqual(orphan(vs, cutoff="2026-09-05"), [])

    def test_an_untagged_manifest_is_left_alone(self):
        vs = [tv(1, [], "2026-09-01")]
        self.assertEqual(orphan(vs, cutoff="2026-09-05"), [])
