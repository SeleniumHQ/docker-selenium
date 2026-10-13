#!/usr/bin/env bash

VERSION=$1
BUILD_DATE=$2
NAMESPACE=$3
PUSH_IMAGE="${4:-false}"
BROWSER=$5
RELEASE_OLD_VERSION="${6:-false}"
PLATFORM="${7:-linux/amd64}"
# Set by deploy.yml when the release promotes its tested images rather than
# rebuilding them. See retag() below.
PROMOTE_TAGS="${PROMOTE_TAGS:-false}"
PROMOTE_GHCR_NAMESPACE="${PROMOTE_GHCR_NAMESPACE:-}"

TAG_VERSION=${VERSION}-${BUILD_DATE}
NAMESPACE=${NAME:-selenium}

# Give one already-published image another tag.
#
# PROMOTE_TAGS=true means the source lives in a registry and was never built
# here: a release now publishes the manifest its tests ran against instead of
# rebuilding it. `docker tag` cannot express that - it needs the image locally,
# and a `docker pull` brings back only the runner's architecture, so the browser
# tags would come out single-architecture while the release tags they alias are
# multi-architecture. imagetools works on the index, registry to registry.
#
# PROMOTE_GHCR_NAMESPACE, when set, mirrors in the same call. The Makefile's
# tag_and_push_browser_images_ghcr cannot do it afterwards, because it discovers
# what to mirror with `docker images` - and on this path the local store is
# empty.
function retag() {
  local __image=$1
  local __tag=$2
  local __source="${NAMESPACE}/${__image}:${TAG_VERSION}"

  if [ "${PROMOTE_TAGS}" = "true" ]; then
    local __targets=(--tag "${NAMESPACE}/${__image}:${__tag}")
    if [ -n "${PROMOTE_GHCR_NAMESPACE}" ]; then
      __targets+=(--tag "${PROMOTE_GHCR_NAMESPACE}/${__image}:${__tag}")
    fi
    docker buildx imagetools create "${__targets[@]}" "${__source}"
    echo "Tagged ${NAMESPACE}/${__image}:${__tag}"
    return
  fi

  docker tag "${__source}" "${NAMESPACE}/${__image}:${__tag}"
  echo "Tagged ${NAMESPACE}/${__image}:${__tag}"
  if [ "${PUSH_IMAGE}" = true ]; then
    docker push "${NAMESPACE}/${__image}:${__tag}"
  fi
}

function short_version() {
  local __long_version=$1
  local __version_split=(${__long_version//./ })
  echo "${__version_split[0]}.${__version_split[1]}"
}

echo "Tagging images for browser ${BROWSER}, version ${VERSION}, build date ${BUILD_DATE}, namespace ${NAMESPACE}"

case "${BROWSER}" in

chrome)
  echo "Selenium Grid version -> ${TAG_VERSION}"
  CHROME_VERSION=$(docker run --platform ${PLATFORM} --rm ${NAMESPACE}/node-chrome:${TAG_VERSION} google-chrome --version | awk '{print $3}')
  echo "Chrome version -> "${CHROME_VERSION}
  CHROME_SHORT_VERSION="$(short_version ${CHROME_VERSION})"
  echo "Short Chrome version -> "${CHROME_SHORT_VERSION}

  CHROMEDRIVER_VERSION=$(docker run --platform ${PLATFORM} --rm ${NAMESPACE}/node-chrome:${TAG_VERSION} chromedriver --version | awk '{print $2}')
  echo "ChromeDriver version -> "${CHROMEDRIVER_VERSION}
  CHROMEDRIVER_SHORT_VERSION="$(short_version ${CHROMEDRIVER_VERSION})"
  echo "Short ChromeDriver version -> "${CHROMEDRIVER_SHORT_VERSION}

  CHROME_TAGS=(
    ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${CHROME_VERSION}-${BUILD_DATE}
    ## Short versions
    ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${CHROME_SHORT_VERSION}-${BUILD_DATE}
  )
  if [ "${RELEASE_OLD_VERSION}" = "false" ]; then
    CHROME_TAGS+=(
      # Browser version and browser driver version
      ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}
      # Browser version
      ${CHROME_VERSION}
      # Browser version and browser driver version
      ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}
      # Browser version
      ${CHROME_SHORT_VERSION}
    )
  fi

  for chrome_tag in "${CHROME_TAGS[@]}"; do
    retag node-chrome "${chrome_tag}"
    retag standalone-chrome "${chrome_tag}"
  done

  ;;
chromium)
  echo "Selenium Grid version -> ${TAG_VERSION}"
  CHROMIUM_VERSION=$(docker run --rm ${NAMESPACE}/node-chromium:${TAG_VERSION} chromium --version | awk '{print $2}')
  echo "Chromium version -> "${CHROMIUM_VERSION}
  CHROMIUM_SHORT_VERSION="$(short_version ${CHROMIUM_VERSION})"
  echo "Short Chromium version -> "${CHROMIUM_SHORT_VERSION}

  CHROMEDRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-chromium:${TAG_VERSION} chromedriver --version | awk '{print $2}')
  echo "ChromeDriver version -> "${CHROMEDRIVER_VERSION}
  CHROMEDRIVER_SHORT_VERSION="$(short_version ${CHROMEDRIVER_VERSION})"
  echo "Short ChromeDriver version -> "${CHROMEDRIVER_SHORT_VERSION}

  CHROMIUM_TAGS=(
    ${CHROMIUM_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${CHROMIUM_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${CHROMIUM_VERSION}-${BUILD_DATE}
    ## Short versions
    ${CHROMIUM_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${CHROMIUM_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${CHROMIUM_SHORT_VERSION}-${BUILD_DATE}
  )
  if [ "${RELEASE_OLD_VERSION}" = "false" ]; then
    CHROMIUM_TAGS+=(
      # Browser version and browser driver version
      ${CHROMIUM_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}
      # Browser version
      ${CHROMIUM_VERSION}
      # Browser version and browser driver version
      ${CHROMIUM_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}
      # Browser version
      ${CHROMIUM_SHORT_VERSION}
    )
  fi

  for chromium_tag in "${CHROMIUM_TAGS[@]}"; do
    retag node-chromium "${chromium_tag}"
    retag standalone-chromium "${chromium_tag}"
  done

  ;;
edge)
  echo "Selenium Grid version -> ${TAG_VERSION}"
  EDGE_VERSION=$(docker run --rm ${NAMESPACE}/node-edge:${TAG_VERSION} microsoft-edge --version | awk '{print $3}')
  echo "Edge version -> "${EDGE_VERSION}
  EDGE_SHORT_VERSION="$(short_version ${EDGE_VERSION})"
  echo "Short Edge version -> "${EDGE_SHORT_VERSION}

  EDGEDRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-edge:${TAG_VERSION} msedgedriver --version | awk '{print $4}')
  echo "EdgeDriver version -> "${EDGEDRIVER_VERSION}
  EDGEDRIVER_SHORT_VERSION="$(short_version ${EDGEDRIVER_VERSION})"
  echo "Short EdgeDriver version -> "${EDGEDRIVER_SHORT_VERSION}

  EDGE_TAGS=(
    ${EDGE_VERSION}-edgedriver-${EDGEDRIVER_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${EDGE_VERSION}-edgedriver-${EDGEDRIVER_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${EDGE_VERSION}-${BUILD_DATE}
    ## Short versions
    ${EDGE_SHORT_VERSION}-edgedriver-${EDGEDRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${EDGE_SHORT_VERSION}-edgedriver-${EDGEDRIVER_SHORT_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${EDGE_SHORT_VERSION}-${BUILD_DATE}
  )
  if [ "${RELEASE_OLD_VERSION}" = "false" ]; then
    EDGE_TAGS+=(
      # Browser version and browser driver version
      ${EDGE_VERSION}-edgedriver-${EDGEDRIVER_VERSION}
      # Browser version
      ${EDGE_VERSION}
      # Browser version and browser driver version
      ${EDGE_SHORT_VERSION}-edgedriver-${EDGEDRIVER_SHORT_VERSION}
      # Browser version
      ${EDGE_SHORT_VERSION}
    )
  fi

  for edge_tag in "${EDGE_TAGS[@]}"; do
    retag node-edge "${edge_tag}"
    retag standalone-edge "${edge_tag}"
  done

  ;;
firefox)
  echo "Selenium Grid version -> ${TAG_VERSION}"
  FIREFOX_VERSION=$(docker run --rm ${NAMESPACE}/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
  echo "Firefox version -> "${FIREFOX_VERSION}
  FIREFOX_SHORT_VERSION="$(short_version ${FIREFOX_VERSION})"
  echo "Short Firefox version -> "${FIREFOX_SHORT_VERSION}
  GECKODRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-firefox:${TAG_VERSION} geckodriver --version | awk 'NR==1{print $2}')
  echo "GeckoDriver version -> "${GECKODRIVER_VERSION}
  GECKODRIVER_SHORT_VERSION="$(short_version ${GECKODRIVER_VERSION})"
  echo "Short GeckoDriver version -> "${GECKODRIVER_SHORT_VERSION}

  FIREFOX_TAGS=(
    ${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${FIREFOX_VERSION}-${BUILD_DATE}
    ## Short versions
    ${FIREFOX_SHORT_VERSION}-geckodriver-${GECKODRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${FIREFOX_SHORT_VERSION}-geckodriver-${GECKODRIVER_SHORT_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${FIREFOX_SHORT_VERSION}-${BUILD_DATE}
  )
  if [ "${RELEASE_OLD_VERSION}" = "false" ]; then
    FIREFOX_TAGS+=(
      # Browser version and browser driver version
      ${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}
      # Browser version
      ${FIREFOX_VERSION}
      # Browser version and browser driver version
      ${FIREFOX_SHORT_VERSION}-geckodriver-${GECKODRIVER_SHORT_VERSION}
      # Browser version
      ${FIREFOX_SHORT_VERSION}
    )
  fi

  for firefox_tag in "${FIREFOX_TAGS[@]}"; do
    retag node-firefox "${firefox_tag}"
    retag standalone-firefox "${firefox_tag}"
  done

  ;;
chrome-for-testing)
  echo "Selenium Grid version -> ${TAG_VERSION}"
  CHROME_VERSION=$(docker run --platform ${PLATFORM} --rm ${NAMESPACE}/node-chrome-for-testing:${TAG_VERSION} google-chrome --version | awk '{print $5}')
  echo "Chrome for Testing version -> "${CHROME_VERSION}
  CHROME_SHORT_VERSION="$(short_version ${CHROME_VERSION})"
  echo "Short Chrome for Testing version -> "${CHROME_SHORT_VERSION}

  CHROMEDRIVER_VERSION=$(docker run --platform ${PLATFORM} --rm ${NAMESPACE}/node-chrome-for-testing:${TAG_VERSION} chromedriver --version | awk '{print $2}')
  echo "ChromeDriver version -> "${CHROMEDRIVER_VERSION}
  CHROMEDRIVER_SHORT_VERSION="$(short_version ${CHROMEDRIVER_VERSION})"
  echo "Short ChromeDriver version -> "${CHROMEDRIVER_SHORT_VERSION}

  CHROME_TAGS=(
    ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${CHROME_VERSION}-${BUILD_DATE}
    ## Short versions
    ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
    # Browser version and browser driver version plus build date
    ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-${BUILD_DATE}
    # Browser version and build date
    ${CHROME_SHORT_VERSION}-${BUILD_DATE}
  )
  if [ "${RELEASE_OLD_VERSION}" = "false" ]; then
    CHROME_TAGS+=(
      # Browser version and browser driver version
      ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}
      # Browser version
      ${CHROME_VERSION}
      # Browser version and browser driver version
      ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}
      # Browser version
      ${CHROME_SHORT_VERSION}
    )
  fi

  for chrome_tag in "${CHROME_TAGS[@]}"; do
    retag node-chrome-for-testing "${chrome_tag}"
    retag standalone-chrome-for-testing "${chrome_tag}"
  done

  ;;
*)
  echo "Unknown browser!"
  ;;
esac
