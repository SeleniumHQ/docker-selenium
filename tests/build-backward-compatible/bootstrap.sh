#!/usr/bin/env bash
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python3 -m pip install pyyaml==6.0.1 \
                      | grep -v 'Requirement already satisfied'

cd ..

SELENIUM_VERSION=$1
CDP_VERSIONS=$2
BROWSER=${3:-"all"}
REUSE_BASE=${4:-"false"}
PUSH_IMAGE=${5:-"false"}
SKIP_BUILD=${6:-"false"}
RELEASE_OLD_VERSION=${7:-"true"}

IFS=',' read -ra VERSION_LIST <<< "$CDP_VERSIONS"

mkdir -p CHANGELOG/${SELENIUM_VERSION}

python3 tests/build-backward-compatible/fetch_firefox_version.py
python3 tests/build-backward-compatible/fetch_version.py

for CDP_VERSION in "${VERSION_LIST[@]}"; do
  python3 tests/build-backward-compatible/builder.py ${SELENIUM_VERSION} ${CDP_VERSION} ${BROWSER}
  export $(cat .env | xargs)
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "firefox" ] && [ "${SKIP_BUILD}" = "false" ]; then
    if [ -n "${FIREFOX_VERSION}" ]; then
      BUILD_ARGS="--build-arg FIREFOX_VERSION=${FIREFOX_VERSION} --build-arg FIREFOX_DOWNLOAD_URL=${FIREFOX_DOWNLOAD_URL}"
      if [ "${REUSE_BASE}" = "true" ]; then
        BUILD_ARGS="${BUILD_ARGS}" PLATFORMS=${PLATFORMS} make firefox_only
        if [ $? -ne 0 ]; then
          echo "Error building Node image"
          exit 1
        fi
        BUILD_ARGS="${BUILD_ARGS}" PLATFORMS=${PLATFORMS} make standalone_firefox_only
      else
        BUILD_ARGS="${BUILD_ARGS}" PLATFORMS=${PLATFORMS} make standalone_firefox
      fi
    else
      echo "Firefox version not found in matrix for input ${CDP_VERSION}"
      exit 1
    fi
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "edge" ] && [ "${SKIP_BUILD}" = "false" ]; then
    if [ -n "${EDGE_VERSION}" ]; then
      BUILD_ARGS="--build-arg EDGE_VERSION=${EDGE_VERSION}"
      if [ "${REUSE_BASE}" = "true" ]; then
        BUILD_ARGS="${BUILD_ARGS}" make edge_only
        if [ $? -ne 0 ]; then
          echo "Error building Node image"
          exit 1
        fi
        BUILD_ARGS="${BUILD_ARGS}" make standalone_edge_only
      else
        BUILD_ARGS="${BUILD_ARGS}" make standalone_edge
      fi
    else
      echo "Edge version not found in matrix for input ${CDP_VERSION}"
      exit 1
    fi
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "chrome" ] && [ "${SKIP_BUILD}" = "false" ]; then
    if [ -n "${CHROME_VERSION}" ]; then
      BUILD_ARGS="--build-arg CHROME_VERSION=${CHROME_VERSION}"
      if [ "${REUSE_BASE}" = "true" ]; then
        BUILD_ARGS="${BUILD_ARGS}" make chrome_only
        if [ $? -ne 0 ]; then
          echo "Error building Node image"
          exit 1
        fi
        BUILD_ARGS="${BUILD_ARGS}" make standalone_chrome_only
      else
        BUILD_ARGS="${BUILD_ARGS}" make standalone_chrome
      fi
    else
      echo "Chrome version not found in matrix for input ${CDP_VERSION}"
      exit 1
    fi
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "firefox" ]; then
      TAG_LOG_OUTPUT="$(PUSH_IMAGE=${PUSH_IMAGE} RELEASE_OLD_VERSION=${RELEASE_OLD_VERSION} make tag_and_push_firefox_images)"
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "edge" ]; then
      TAG_LOG_OUTPUT="$(PUSH_IMAGE=${PUSH_IMAGE} RELEASE_OLD_VERSION=${RELEASE_OLD_VERSION} make tag_and_push_edge_images)"
  fi
  if [ "${BROWSER}" = "all" ] || [ "${BROWSER}" = "chrome" ]; then
      TAG_LOG_OUTPUT="$(PUSH_IMAGE=${PUSH_IMAGE} RELEASE_OLD_VERSION=${RELEASE_OLD_VERSION} make tag_and_push_chrome_images)"
  fi

  if [ "${PUSH_IMAGE}" = "false" ]; then
    echo "\`\`\`" > ./CHANGELOG/${SELENIUM_VERSION}/${BROWSER}_${CDP_VERSION}.md
    echo "$TAG_LOG_OUTPUT" | while IFS= read -r line; do
      echo "$line" >> ./CHANGELOG/${SELENIUM_VERSION}/${BROWSER}_${CDP_VERSION}.md
    done ;
    echo "\`\`\`" >> ./CHANGELOG/${SELENIUM_VERSION}/${BROWSER}_${CDP_VERSION}.md
  else
    echo "${TAG_LOG_OUTPUT}"
  fi
done
