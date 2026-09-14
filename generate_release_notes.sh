#!/usr/bin/env bash

LATEST_TAG=$1
HEAD_BRANCH=$2
GRID_VERSION=$3
BUILD_DATE=$4
NAMESPACE=${NAME:-selenium}
FFMPEG_TAG_VERSION=$(grep FFMPEG_TAG_VERSION Makefile | sed 's/.*,\([^)]*\))/\1/p' | head -n 1)
AUTHORS=${AUTHORS:-"SeleniumHQ"}
GHCR_NAMESPACE=${GHCR_NAMESPACE:-ghcr.io/$(echo "${AUTHORS}" | tr '[:upper:]' '[:lower:]')}

TAG_VERSION=${GRID_VERSION}-${BUILD_DATE}

# The tag the images were actually published under. A release publishes
# <grid version>-<build date>, which is the default; the nightly publishes
# :nightly and nothing else, so nightly.yml passes IMAGE_TAG=nightly. Reading a
# tag that was never published is what left every cell of the table below blank.
#
# Video is the one image that does not carry the grid tag on the release path -
# it is built as <ffmpeg tag>-<build date> - so it gets a tag of its own.
IMAGE_TAG=${IMAGE_TAG:-${TAG_VERSION}}
VIDEO_IMAGE_TAG=${VIDEO_IMAGE_TAG:-${FFMPEG_TAG_VERSION}-${BUILD_DATE}}

if [ -z "${LATEST_TAG}" ] || [ -z "${HEAD_BRANCH}" ] || [ -z "${GRID_VERSION}" ] || [ -z "${BUILD_DATE}" ]; then
  echo "usage: $0 <previous tag> <head branch> <grid version> <build date>" >&2
  exit 1
fi

# `git log ...<branch>` with an empty left-hand side is `HEAD...<branch>`, which
# on a checkout of that very branch is empty - a silent, changelog-shaped hole in
# the notes. Resolve both ends up front and say which one is missing instead.
for rev in "${LATEST_TAG}" "${HEAD_BRANCH}"; do
  if ! git rev-parse --verify --quiet "${rev}^{commit}" >/dev/null; then
    echo "cannot resolve '${rev}': the changelog would be empty" >&2
    exit 1
  fi
done

echo "### Changelog" >release_notes.md
git --no-pager log "${LATEST_TAG}...${HEAD_BRANCH}" --pretty=format:"* [\`%h\`](http://github.com/seleniumhq/docker-selenium/commit/%H) - %s :: %an" --reverse >>release_notes.md

# --- versions, read out of the published images -------------------------------
#
# On the promotion path the deploy job builds nothing, so none of these images is
# in the local store and the `docker run` that reads one pulls it. The browser
# images together are far larger than the runner has free, so each is dropped
# again as soon as its values have been read. Anything that was already in the
# store came from a local build and is left where the rest of the job expects it.
PRESENT_BEFORE=" $(docker images --format '{{.Repository}}:{{.Tag}}' | tr '\n' ' ')"

drop_image() {
  case "${PRESENT_BEFORE}" in
  *" $1 "*) return 0 ;;
  esac
  docker rmi -f "$1" >/dev/null 2>&1 || true
}

BASE_IMAGE=${NAMESPACE}/base:${IMAGE_TAG}
GRID_REVISION=$(docker run --entrypoint="" --rm ${BASE_IMAGE} java -jar /opt/selenium/selenium-server.jar info --version | awk '{print $5}')
JRE_VERSION=$(docker run --entrypoint="" --rm ${BASE_IMAGE} java --version | grep -oP '\b\d+\.\d+\.\d+\b' | head -1)
OS_VERSION=$(docker run --entrypoint="" --rm ${BASE_IMAGE} cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)
drop_image ${BASE_IMAGE}

CHROME_IMAGE=${NAMESPACE}/node-chrome:${IMAGE_TAG}
CHROME_VERSION=$(docker run --rm ${CHROME_IMAGE} google-chrome --version | awk '{print $3}')
CHROMEDRIVER_VERSION=$(docker run --rm ${CHROME_IMAGE} chromedriver --version | awk '{print $2}')
CHROME_ARM64_VERSION=$(docker run --rm --platform linux/arm64 ${CHROME_IMAGE} google-chrome --version | awk '{print $3}')
CHROMEDRIVER_ARM64_VERSION=$(docker run --rm --platform linux/arm64 ${CHROME_IMAGE} chromedriver --version | awk '{print $2}')
drop_image ${CHROME_IMAGE}

CFT_IMAGE=${NAMESPACE}/node-chrome-for-testing:${IMAGE_TAG}
CFT_VERSION=$(docker run --rm ${CFT_IMAGE} google-chrome --version | awk '{print $5}')
drop_image ${CFT_IMAGE}

CHROMIUM_IMAGE=${NAMESPACE}/node-chromium:${IMAGE_TAG}
CHROMIUM_VERSION=$(docker run --rm ${CHROMIUM_IMAGE} chromium --version | awk '{print $2}')
drop_image ${CHROMIUM_IMAGE}

EDGE_IMAGE=${NAMESPACE}/node-edge:${IMAGE_TAG}
EDGE_VERSION=$(docker run --rm ${EDGE_IMAGE} microsoft-edge --version | awk '{print $3}')
EDGEDRIVER_VERSION=$(docker run --rm ${EDGE_IMAGE} msedgedriver --version | awk '{print $4}')
drop_image ${EDGE_IMAGE}

FIREFOX_IMAGE=${NAMESPACE}/node-firefox:${IMAGE_TAG}
FIREFOX_VERSION=$(docker run --rm ${FIREFOX_IMAGE} firefox --version | awk '{print $3}')
GECKODRIVER_VERSION=$(docker run --rm ${FIREFOX_IMAGE} geckodriver --version | awk 'NR==1{print $2}')
FIREFOX_ARM64_VERSION=$(docker run --rm --platform linux/arm64 ${FIREFOX_IMAGE} firefox --version | awk '{print $3}')
drop_image ${FIREFOX_IMAGE}

VIDEO_IMAGE=${NAMESPACE}/video:${VIDEO_IMAGE_TAG}
FFMPEG_VERSION=$(docker run --entrypoint="" --rm ${VIDEO_IMAGE} ffmpeg -version | awk '{print $3}' | head -n 1)
RCLONE_VERSION=$(docker run --entrypoint="" --rm ${VIDEO_IMAGE} rclone version | head -n 1 | awk '{print $2}' | tr -d 'v')
drop_image ${VIDEO_IMAGE}

# A version that came back empty means the image it was read from was not
# published under ${IMAGE_TAG}, or could not be run. Publishing the table anyway
# is how a release ends up looking empty, so name what failed and stop - the
# release step has not run yet, so the previous notes stay up.
missing=""
for version in GRID_REVISION JRE_VERSION OS_VERSION CHROME_VERSION CHROMEDRIVER_VERSION \
  CHROME_ARM64_VERSION CHROMEDRIVER_ARM64_VERSION CFT_VERSION CHROMIUM_VERSION \
  EDGE_VERSION EDGEDRIVER_VERSION FIREFOX_VERSION GECKODRIVER_VERSION \
  FIREFOX_ARM64_VERSION FFMPEG_VERSION RCLONE_VERSION; do
  [ -n "${!version}" ] || missing="${missing} ${version}"
done
if [ -n "${missing}" ]; then
  echo "could not read from the images published as '${IMAGE_TAG}':${missing}" >&2
  exit 1
fi

if [[ "${GRID_VERSION}" == *"SNAPSHOT"* ]]; then
  GRID_RELEASE_TAG="nightly"
else
  GRID_RELEASE_TAG="selenium-${GRID_VERSION}"
fi
LINK_GRID_DETAILS="[${GRID_VERSION}](https://github.com/${AUTHORS}/selenium/releases/tag/${GRID_RELEASE_TAG}) (rev [${GRID_REVISION}](https://github.com/${AUTHORS}/selenium/commit/${GRID_REVISION}))"

echo "" >>release_notes.md
echo "### Released versions" >>release_notes.md
echo "| Components | x86_64 (amd64) | aarch64 (arm64/armv8) |" >>release_notes.md
echo "|:----------:|:--------------:|:---------------------:|" >>release_notes.md
echo "| Selenium Grid | ${LINK_GRID_DETAILS} | ${LINK_GRID_DETAILS} |" >>release_notes.md
echo "| Chromium | ${CHROMIUM_VERSION} | ${CHROMIUM_VERSION} |" >>release_notes.md
echo "| Chrome | ${CHROME_VERSION} | ${CHROME_ARM64_VERSION} |" >>release_notes.md
echo "| Chrome for Testing | ${CFT_VERSION} | x |" >>release_notes.md
echo "| ChromeDriver | ${CHROMEDRIVER_VERSION} | ${CHROMEDRIVER_ARM64_VERSION} |" >>release_notes.md
echo "| Edge | ${EDGE_VERSION} | x |" >>release_notes.md
echo "| EdgeDriver | ${EDGEDRIVER_VERSION} | x |" >>release_notes.md
echo "| Firefox | ${FIREFOX_VERSION} | ${FIREFOX_ARM64_VERSION} |" >>release_notes.md
echo "| GeckoDriver | ${GECKODRIVER_VERSION} | ${GECKODRIVER_VERSION} |" >>release_notes.md
echo "| ffmpeg | ${FFMPEG_VERSION} | ${FFMPEG_VERSION} |" >>release_notes.md
echo "| rclone | ${RCLONE_VERSION} | ${RCLONE_VERSION} |" >>release_notes.md
echo "| Java Runtime | ${JRE_VERSION} | ${JRE_VERSION} |" >>release_notes.md
echo "| OS | ${OS_VERSION} | ${OS_VERSION} |" >>release_notes.md

# --- what was published -------------------------------------------------------
#
# `docker images` listed the local store, which the promotion path never fills,
# so both sections below came out as a bare table header. Ask the registry
# instead: the digest it answers with is the one users pull, and it is the same
# check for a build and for a promotion.
#
# The image list comes from the Makefile so the two cannot drift apart.
PUBLISHED_IMAGES=$(make --no-print-directory print_ci_images)
if [ -z "${PUBLISHED_IMAGES}" ]; then
  echo "could not read the image list from the Makefile" >&2
  exit 1
fi

list_published_images() {
  local registry=$1
  local image ref raw digest platforms row
  local -a rows=()
  local ref_width=5 platform_width=9

  for image in ${PUBLISHED_IMAGES}; do
    if [ "${image}" = "video" ]; then
      ref="${registry}/${image}:${VIDEO_IMAGE_TAG}"
    else
      ref="${registry}/${image}:${IMAGE_TAG}"
    fi
    if ! raw=$(docker buildx imagetools inspect --raw "${ref}" 2>/dev/null); then
      echo "not published: ${ref}" >&2
      continue
    fi
    # The architectures the manifest list actually covers, so an image that
    # quietly lost one is visible in the notes. `unknown` is the attestation
    # entry buildx attaches alongside the real ones.
    platforms=$(printf '%s' "${raw}" | jq -r '[.manifests[]? | select(.platform.os != "unknown") | "\(.platform.os)/\(.platform.architecture)"] | unique | join(",")')
    digest=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' "${ref}" 2>/dev/null)
    [ ${#ref} -gt ${ref_width} ] && ref_width=${#ref}
    [ ${#platforms} -gt ${platform_width} ] && platform_width=${#platforms}
    rows+=("${ref}"$'\t'"${platforms:--}"$'\t'"${digest:--}")
  done

  if [ ${#rows[@]} -eq 0 ]; then
    echo "none of the images are published in ${registry}" >&2
    return 1
  fi

  printf "%-${ref_width}s  %-${platform_width}s  %s\n" "IMAGE" "PLATFORMS" "DIGEST"
  for row in "${rows[@]}"; do
    IFS=$'\t' read -r ref platforms digest <<<"${row}"
    printf "%-${ref_width}s  %-${platform_width}s  %s\n" "${ref}" "${platforms}" "${digest}"
  done
}

echo "" >>release_notes.md
echo "### Published Docker images on [Docker Hub](https://hub.docker.com/u/${NAMESPACE})" >>release_notes.md
echo "<details>" >>release_notes.md
echo "<summary>Click to see published Docker images</summary>" >>release_notes.md
echo "" >>release_notes.md
echo '```' >>release_notes.md
list_published_images "${NAMESPACE}" >>release_notes.md || exit 1
echo '```' >>release_notes.md
echo "" >>release_notes.md
echo "</details>" >>release_notes.md

echo "" >>release_notes.md

echo "### Published Docker images on [GitHub Container Registry](https://github.com/orgs/${AUTHORS}/packages?repo_name=docker-selenium)" >>release_notes.md
echo "<details>" >>release_notes.md
echo "<summary>Click to see published Docker images</summary>" >>release_notes.md
echo "" >>release_notes.md
echo '```' >>release_notes.md
list_published_images "${GHCR_NAMESPACE}" >>release_notes.md || exit 1
echo '```' >>release_notes.md
echo "" >>release_notes.md
echo "</details>" >>release_notes.md

echo "" >>release_notes.md
chart_version=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 cat | grep ^version | cut -d ':' -f 2 | tr -d '[:space:]')
echo "### Published Helm chart version [selenium-grid-${chart_version}](https://github.com/${AUTHORS}/docker-selenium/releases/tag/selenium-grid-${chart_version})" >>release_notes.md
