import importlib.util
import io
import pathlib
import unittest
import urllib.error
from datetime import datetime, timedelta, timezone

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "ci" / "cleanup_pr_images.py"
spec = importlib.util.spec_from_file_location("cleanup_pr_images", MODULE_PATH)
cp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cp)


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
        if any(not cp.is_ci_tag(t) for t in tags):
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

    def test_accepts_the_completeness_marker(self):
        # build-images tags base:src-<hash>-complete once the whole set has
        # merged, on the same manifest as src-<hash>. Unrecognised, it would read
        # as a tag outside the CI families and protect every base manifest from
        # cleanup for ever.
        self.assertTrue(cp.SRC_TAG.match("src-331808bba75d-complete"))

    def test_still_rejects_the_per_architecture_tags(self):
        # Deliberate, and load-bearing. SRC_TAG identifies an index, and every
        # sweep judges indexes only: src-<hash>-amd64 is the child manifest the
        # index points at, not a copy of it, so deleting one on its own breaks an
        # index that may still be in use. ARCH_TAG matches those instead, and
        # delete_family removes them with their index.
        for tag in ["src-331808bba75d-amd64", "src-331808bba75d-arm64"]:
            self.assertIsNone(cp.SRC_TAG.match(tag), tag)
            self.assertTrue(cp.ARCH_TAG.match(tag), tag)
            self.assertTrue(cp.is_ci_tag(tag), tag)


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


class DurableMarkerTest(unittest.TestCase):
    """pr-<N> moves; pr-<N>-<hash> does not, so a closed PR's whole set is findable."""

    def test_both_marker_forms_yield_the_pull_request_number(self):
        self.assertEqual(cp.PR_TAG.match("pr-3229").group(1), "3229")
        self.assertEqual(cp.PR_TAG.match("pr-3229-331808bba75d").group(1), "3229")

    def test_a_marker_suffix_must_be_a_hex_hash(self):
        for tag in ["pr-3229-notahash", "pr-3229-", "pr-3229-abc", "pr-"]:
            self.assertIsNone(cp.PR_TAG.match(tag), tag)

    def test_closing_a_pull_request_now_reaches_every_build_it_made(self):
        # three commits, three manifests; pr-100 moved to the newest, but each
        # build kept its own durable marker
        vs = [
            version(1, ["src-a11111", "pr-100-a11111"]),
            version(2, ["src-b22222", "pr-100-b22222"]),
            version(3, ["src-c33333", "pr-100-c33333", "pr-100"]),
        ]
        self.assertEqual(sorted(decide(vs, closed={100})), [1, 2, 3])

    def test_an_open_pull_request_keeps_all_of_its_builds(self):
        vs = [
            version(1, ["src-a11111", "pr-100-a11111"]),
            version(2, ["src-b22222", "pr-100-b22222", "pr-100"]),
        ]
        self.assertEqual(decide(vs, closed=set()), [])

    def test_a_manifest_two_pull_requests_used_survives_while_either_is_open(self):
        # PR 101 reused what PR 100 built, so both markers sit on one manifest
        vs = [version(1, ["src-a11111", "pr-100-a11111", "pr-101-a11111"])]
        self.assertEqual(decide(vs, closed={100}), [])
        self.assertEqual(decide(vs, closed={100, 101}), [1])

    def test_targeting_one_pull_request_still_reaches_its_older_builds(self):
        vs = [
            version(1, ["src-a11111", "pr-100-a11111"]),
            version(2, ["src-b22222", "pr-101-b22222"]),
        ]
        self.assertEqual(decide(vs, closed={100, 101}, target_pr=100), [1])


def version(vid, tags, created="2020-01-01T00:00:00Z"):
    return {"id": vid, "created_at": created, "metadata": {"container": {"tags": list(tags)}}}


class RecordingApi:
    """Stands in for the GitHub API: serves one package, records the deletes.

    These tests drive the real functions rather than a restatement of their
    rules, which is the only way a defect in delete_family can show up here.
    """

    def __init__(self, versions, fails=()):
        self.versions = versions
        self.fails = set(fails)
        self.deleted = []

    def request(self, url, token, method="GET"):
        if method != "DELETE":
            raise AssertionError(f"unexpected {method} {url}")
        vid = int(url.rsplit("/", 1)[-1])
        if vid in self.fails:
            raise urllib.error.HTTPError(url, 403, "Forbidden", {}, None)
        self.deleted.append(vid)

    def install(self, testcase):
        testcase.addCleanup(setattr, cp, "_request", cp._request)
        testcase.addCleanup(setattr, cp, "versions", cp.versions)
        cp._request = self.request
        cp.versions = lambda owner, image, token: self.versions


class ArchChildrenTest(unittest.TestCase):
    def test_groups_children_under_the_hash_of_their_index(self):
        found = cp.arch_children(
            [
                version(1, ["src-aaaaaaaaaaaa", "src-aaaaaaaaaaaa-complete"]),
                version(2, ["src-aaaaaaaaaaaa-amd64"]),
                version(3, ["src-aaaaaaaaaaaa-arm64"]),
                version(4, ["src-bbbbbbbbbbbb-amd64"]),
            ]
        )
        self.assertEqual(sorted(v["id"] for v in found["aaaaaaaaaaaa"]), [2, 3])
        self.assertEqual([v["id"] for v in found["bbbbbbbbbbbb"]], [4])

    def test_the_index_itself_is_not_a_child(self):
        self.assertEqual(cp.arch_children([version(1, ["src-aaaaaaaaaaaa"])]), {})

    def test_a_pr_alias_reveals_the_hash_it_belongs_to(self):
        self.assertEqual(cp.tag_hash("pr-3229-aaaaaaaaaaaa"), "aaaaaaaaaaaa")
        self.assertEqual(cp.tag_hash("src-aaaaaaaaaaaa-amd64"), "aaaaaaaaaaaa")
        self.assertIsNone(cp.tag_hash("pr-3229"))
        self.assertIsNone(cp.tag_hash("latest"))


class DeleteFamilyTest(unittest.TestCase):
    def test_an_index_takes_its_architecture_children_with_it(self):
        api = RecordingApi([])
        api.install(self)
        index = version(1, ["src-aaaaaaaaaaaa", "src-aaaaaaaaaaaa-complete"])
        children = cp.arch_children([version(2, ["src-aaaaaaaaaaaa-amd64"]), version(3, ["src-aaaaaaaaaaaa-arm64"])])
        removed, problems = cp.delete_family("seleniumhq", "base", index, children, "t")
        self.assertEqual(removed, 3)
        self.assertEqual(problems, [])
        self.assertEqual(api.deleted, [1, 2, 3], "the index must be deleted before its children")

    def test_children_of_another_hash_are_left_alone(self):
        api = RecordingApi([])
        api.install(self)
        children = cp.arch_children([version(9, ["src-bbbbbbbbbbbb-amd64"])])
        cp.delete_family("seleniumhq", "base", version(1, ["src-aaaaaaaaaaaa"]), children, "t")
        self.assertEqual(api.deleted, [1])

    def test_a_refused_delete_is_reported_rather_than_raised(self):
        api = RecordingApi([], fails={2})
        api.install(self)
        children = cp.arch_children([version(2, ["src-aaaaaaaaaaaa-amd64"])])
        removed, problems = cp.delete_family("seleniumhq", "base", version(1, ["src-aaaaaaaaaaaa"]), children, "t")
        self.assertEqual(removed, 1)
        self.assertEqual(len(problems), 1)
        self.assertIn("403", problems[0])


class OrphanSweepReachesChildrenTest(unittest.TestCase):
    def test_the_children_no_sweep_could_previously_see_are_collected(self):
        api = RecordingApi(
            [
                version(1, ["src-aaaaaaaaaaaa", "src-aaaaaaaaaaaa-complete"]),
                version(2, ["src-aaaaaaaaaaaa-amd64"]),
                version(3, ["src-aaaaaaaaaaaa-arm64"]),
            ]
        )
        api.install(self)
        removed, problems = cp.prune_orphans("seleniumhq", "base", "t", older_than_days=7)
        self.assertEqual(removed, 3)
        self.assertEqual(sorted(api.deleted), [1, 2, 3])
        self.assertEqual(problems, [])

    def test_a_child_is_never_deleted_while_its_index_is_too_new(self):
        recent = (datetime.now(timezone.utc) + timedelta(days=1)).isoformat()
        api = RecordingApi(
            [
                version(1, ["src-aaaaaaaaaaaa"], created=recent),
                version(2, ["src-aaaaaaaaaaaa-amd64"]),
            ]
        )
        api.install(self)
        removed, _ = cp.prune_orphans("seleniumhq", "base", "t", older_than_days=7)
        self.assertEqual(removed, 0, "deleting a child of a live index breaks that index")
        self.assertEqual(api.deleted, [])

    def test_a_release_tag_still_protects_the_whole_family(self):
        api = RecordingApi(
            [
                version(1, ["src-aaaaaaaaaaaa", "4.48.0"]),
                version(2, ["src-aaaaaaaaaaaa-amd64"]),
            ]
        )
        api.install(self)
        removed, _ = cp.prune_orphans("seleniumhq", "base", "t", older_than_days=7)
        self.assertEqual(removed, 0)
        self.assertEqual(api.deleted, [])

    def test_a_child_shared_with_another_index_is_left_alone(self):
        # Two hashes whose images come out byte-identical share one manifest, and
        # that manifest then carries an arch tag for each. Taking it with one
        # index would break the other.
        api = RecordingApi([])
        api.install(self)
        shared = version(2, ["src-aaaaaaaaaaaa-amd64", "src-bbbbbbbbbbbb-amd64"])
        children = cp.arch_children([shared, version(3, ["src-aaaaaaaaaaaa-arm64"])])
        removed, _ = cp.delete_family("seleniumhq", "base", version(1, ["src-aaaaaaaaaaaa"]), children, "t")
        self.assertEqual(removed, 2)
        self.assertEqual(api.deleted, [1, 3])
        self.assertNotIn(2, api.deleted)
