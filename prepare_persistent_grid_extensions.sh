#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELENIUM_REPO="${SELENIUM_REPO:-${ROOT_DIR}/../selenium}"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/.persistent-grid}"

declare -a REQUIRED_FILES=(
  "${SELENIUM_REPO}/bazel-bin/java/src/org/openqa/selenium/grid/selenium_server_deploy.jar"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "${file}" ]]; then
    cat <<EOF 1>&2
Missing required local Selenium artifact: ${file}

Build the Selenium repo first, for example:
  bazel build //java/src/org/openqa/selenium/grid:selenium_server
EOF
    exit 1
  fi
done

mkdir -p "${OUT_DIR}"
rm -f "${OUT_DIR}/selenium-server.jar"

sudo cp "${SELENIUM_REPO}/bazel-bin/java/src/org/openqa/selenium/grid/selenium_server_deploy.jar" \
  "${OUT_DIR}/selenium-server.jar"

cat <<EOF
Prepared persistent Grid override in:
  ${OUT_DIR}

Included artifacts:
- selenium-server.jar copied from bazel-bin/java/src/org/openqa/selenium/grid/selenium_server_deploy.jar
- no extra Redis or NATS extension jars are required because the
  packaged selenium-server.jar already includes those implementations
EOF
