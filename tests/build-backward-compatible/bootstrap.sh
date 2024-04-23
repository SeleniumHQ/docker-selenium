#!/usr/bin/env bash
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python -m pip install pyyaml==6.0.1 \
                      | grep -v 'Requirement already satisfied'

cd ..

SELENIUM_VERSION=$1
CDP_VERSIONS=$2
BROWSER=${3:-"all"}
PUSH_IMAGE=${4:-"false"}

IFS=',' read -ra VERSION_LIST <<< "$CDP_VERSIONS"

for CDP_VERSION in "${VERSION_LIST[@]}"; do
  python tests/build-backward-compatible/builder.py ${SELENIUM_VERSION} ${CDP_VERSION}
  export $(cat .env | xargs)
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "firefox" ]; then
    if [ -n "${FIREFOX_VERSION}" ]; then
      BUILD_ARGS="--build-arg FIREFOX_VERSION=${FIREFOX_VERSION}"
      BUILD_ARGS="${BUILD_ARGS}" make standalone_firefox
    else
      echo "Firefox version not found in matrix for input ${CDP_VERSION}"
      exit 1
    fi
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "edge" ]; then
    if [ -n "${EDGE_VERSION}" ]; then
      BUILD_ARGS="--build-arg EDGE_VERSION=${EDGE_VERSION}"
      BUILD_ARGS="${BUILD_ARGS}" make standalone_edge
    else
      echo "Edge version not found in matrix for input ${CDP_VERSION}"
      exit 1
    fi
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "chrome" ]; then
    if [ -n "${CHROME_VERSION}" ]; then
      BUILD_ARGS="--build-arg CHROME_VERSION=${CHROME_VERSION}"
      BUILD_ARGS="${BUILD_ARGS}" make standalone_chrome
    else
      echo "Chrome version not found in matrix for input ${CDP_VERSION}"
      exit 1
    fi
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "firefox" ]; then
      TAG_LOG_OUTPUT="$TAG_LOG_OUTPUT $(PUSH_IMAGE=${PUSH_IMAGE} make tag_and_push_firefox_images)"
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "edge" ]; then
      TAG_LOG_OUTPUT="$TAG_LOG_OUTPUT $(PUSH_IMAGE=${PUSH_IMAGE} make tag_and_push_edge_images)"
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "chrome" ]; then
      TAG_LOG_OUTPUT="$TAG_LOG_OUTPUT $(PUSH_IMAGE=${PUSH_IMAGE} make tag_and_push_chrome_images)"
  fi
done

readarray -t LOG_LINES <<< "$TAG_LOG_OUTPUT"
for line in "${LOG_LINES[@]}"; do
    echo "$line"
done
