import importlib.util
import io
import pathlib
import sys
import unittest
from contextlib import redirect_stdout
from unittest import mock

MODULE_PATH = pathlib.Path(__file__).parents[2] / "scripts" / "ci" / "select_pr_tests.py"
spec = importlib.util.spec_from_file_location("select_pr_tests", MODULE_PATH)
spt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(spt)


def run_main(stdin, expected_files):
    output = io.StringIO()
    argv = ["select_pr_tests.py", "--expected-files", str(expected_files)]
    with mock.patch.object(sys, "argv", argv), mock.patch.object(sys, "stdin", io.StringIO(stdin)):
        with redirect_stdout(output):
            spt.main()
    return output.getvalue().split()


class SelectTests(unittest.TestCase):
    def test_chart_changes_run_only_k8s(self):
        for path in (
            "charts/selenium-grid/values.yaml",
            "charts/selenium-grid/templates/hub-deployment.yaml",
            "tests/charts/ci/base-auth-ingress-values.yaml",
            "tests/charts/refValues/simplex-minikube.yaml",
            "tests/charts/make/chart_test.sh",
            "tests/k8s/make/dynamic_grid_test.sh",
        ):
            with self.subTest(path=path):
                self.assertEqual(spt.select([path]), (False, True))

    def test_docker_test_files_run_only_docker(self):
        for path in (
            "tests/config.toml",
            "tests/docker-compose-v3-test-video.yml",
            "tests/docker-compose-v3-test-node-docker.yaml",
            "tests/relay_config.toml",
            "tests/standalone_docker_video_sidecar_config.toml",
        ):
            with self.subTest(path=path):
                self.assertEqual(spt.select([path]), (True, False))

    def test_shared_files_run_both(self):
        for path in (
            "charts/selenium-grid/configs/node/nodeProbe.sh",
            "charts/selenium-grid/certs/gen-cert-helper.sh",
            "tests/charts/make/chart_setup_env.sh",
            "tests/charts/make/chart_check_env.sh",
            "tests/bootstrap.sh",
            "tests/SeleniumTests/__init__.py",
            "tests/requirements.txt",
        ):
            with self.subTest(path=path):
                self.assertEqual(spt.select([path]), (True, True))

    def test_image_and_build_files_run_both(self):
        for path in (
            "Base/Dockerfile",
            "NodeChrome/Dockerfile",
            "Video/video.sh",
            "Makefile",
            ".github/workflows/build-test.yml",
            ".monitoring/exporter/main.go",
            "scripts/ci/select_pr_tests.py",
        ):
            with self.subTest(path=path):
                self.assertEqual(spt.select([path]), (True, True))

    def test_unknown_path_runs_both(self):
        self.assertEqual(spt.select(["some/new/location/file.yaml"]), (True, True))

    def test_similar_prefixes_are_not_matched(self):
        self.assertEqual(spt.select(["charts/other-chart/values.yaml"]), (True, True))
        self.assertEqual(spt.select(["tests/charts-extra/values.yaml"]), (True, True))
        self.assertEqual(spt.select(["tests/config.toml.bak"]), (True, True))

    def test_docs_do_not_widen_the_selection(self):
        self.assertEqual(spt.select(["README.md", "charts/selenium-grid/values.yaml"]), (False, True))
        self.assertEqual(spt.select(["CHANGELOG/4.52.0/chrome.md", "tests/config.toml"]), (True, False))

    def test_only_docs_runs_both(self):
        self.assertEqual(spt.select(["README.md"]), (True, True))

    def test_no_paths_runs_both(self):
        self.assertEqual(spt.select([]), (True, True))

    def test_k8s_and_docker_changes_run_both(self):
        self.assertEqual(spt.select(["tests/charts/ci/a.yaml", "tests/config.toml"]), (True, True))

    def test_shared_file_wins_over_narrow_files(self):
        self.assertEqual(spt.select(["tests/charts/ci/a.yaml", "Makefile"]), (True, True))


class MainTests(unittest.TestCase):
    def test_prints_selection_for_chart_change(self):
        output = run_main("charts/selenium-grid/values.yaml\n", 1)
        self.assertEqual(output, ["run-docker-tests=false", "run-k8s-tests=true"])

    def test_rename_counts_as_one_file_and_checks_both_paths(self):
        output = run_main("tests/charts/ci/new.yaml\tBase/old.yaml\n", 1)
        self.assertEqual(output, ["run-docker-tests=true", "run-k8s-tests=true"])

    def test_rename_inside_one_suite_stays_narrow(self):
        output = run_main("tests/charts/ci/new.yaml\ttests/charts/ci/old.yaml\n", 1)
        self.assertEqual(output, ["run-docker-tests=false", "run-k8s-tests=true"])

    def test_incomplete_file_list_runs_both(self):
        output = run_main("charts/selenium-grid/values.yaml\n", 2)
        self.assertEqual(output, ["run-docker-tests=true", "run-k8s-tests=true"])

    def test_empty_input_runs_both(self):
        output = run_main("", 3)
        self.assertEqual(output, ["run-docker-tests=true", "run-k8s-tests=true"])


if __name__ == "__main__":
    unittest.main()
