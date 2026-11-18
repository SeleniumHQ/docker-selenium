#!/usr/bin/env python3
"""Decide which test suites a pull request needs, from the files it changes.

Reads one changed file per line from stdin. A renamed file is given as
``new<TAB>old``, and both paths count. Prints GitHub Actions outputs:

    run-docker-tests=true|false
    run-k8s-tests=true|false

Only paths known to reach a single suite narrow the selection. Every other path
runs both suites, so a new or shared file is tested by default. Both suites also
run when the file list is empty or incomplete.
"""

import argparse
import fnmatch
import sys

DOCS = "docs"
DOCKER = "docker"
K8S = "k8s"
BOTH = "both"

# The same paths the pull_request trigger in build-test.yml ignores.
DOCS_PATTERNS = ("*.md", "CHANGELOG/*", "tests/build-backward-compatible/*", "scripts/generate_list_env_vars/*")

# Chart files that the images or the Docker tests also use.
SHARED_PATTERNS = (
    "charts/selenium-grid/certs/*",
    "charts/selenium-grid/configs/*",
    "tests/charts/make/chart_check_env.sh",
    "tests/charts/make/chart_setup_env.sh",
)

K8S_PATTERNS = ("charts/selenium-grid/*", "tests/charts/*", "tests/k8s/*")

DOCKER_PATTERNS = (
    "tests/Dockerfile.emulator",
    "tests/config.toml",
    "tests/config_video_sidecar.toml",
    "tests/docker-compose-v3-test-*",
    "tests/relay_config.toml",
    "tests/standalone_docker_config.toml",
    "tests/standalone_docker_video_sidecar_config.toml",
)


def matches(path, patterns):
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def classify(path):
    """Return the suite a changed path can affect."""
    if matches(path, DOCS_PATTERNS):
        return DOCS
    if matches(path, SHARED_PATTERNS):
        return BOTH
    if matches(path, K8S_PATTERNS):
        return K8S
    if matches(path, DOCKER_PATTERNS):
        return DOCKER
    return BOTH


def select(paths):
    """Return (run_docker, run_k8s) for the changed paths."""
    suites = {classify(path) for path in paths} - {DOCS}
    if not suites or BOTH in suites:
        return True, True
    return DOCKER in suites, K8S in suites


def parse_changed_files(lines):
    """Return one list of paths per changed file."""
    return [line.rstrip("\n").split("\t") for line in lines if line.strip()]


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--expected-files", type=int, required=True, help="changed files reported by the pull request")
    args = parser.parse_args()

    changed_files = parse_changed_files(sys.stdin)
    if len(changed_files) != args.expected_files:
        run_docker, run_k8s = True, True
    else:
        run_docker, run_k8s = select(path for paths in changed_files for path in paths)

    print(f"run-docker-tests={str(run_docker).lower()}")
    print(f"run-k8s-tests={str(run_k8s).lower()}")


if __name__ == "__main__":
    main()
