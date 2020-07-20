#!/usr/bin/env bash

VERSION=$1
BUILD_DATE=$2
NAMESPACE=$3
PUSH_IMAGE="${4:-false}"
BROWSER=$5

TAG_VERSION=${VERSION}-${BUILD_DATE}

function short_version() {
    local __long_version=$1
    local __version_split=( ${__long_version//./ } )
    echo "${__version_split[0]}.${__version_split[1]}"
}


echo "Tagging images for browser ${BROWSER}, version ${VERSION}, build date ${BUILD_DATE}, namespace ${NAMESPACE}"

case "${BROWSER}" in

chrome)
  CHROME_VERSION=$(docker run --rm selenium/node-chrome:${TAG_VERSION} google-chrome --version | awk '{print $3}')
  echo "Chrome version -> "${CHROME_VERSION}
  CHROME_SHORT_VERSION="$(short_version ${CHROME_VERSION})"
  echo "Short Chrome version -> "${CHROME_SHORT_VERSION}

  CHROMEDRIVER_VERSION=$(docker run --rm selenium/node-chrome:${TAG_VERSION} chromedriver --version | awk '{print $2}')
  echo "ChromeDriver version -> "${CHROMEDRIVER_VERSION}
  CHROMEDRIVER_SHORT_VERSION="$(short_version ${CHROMEDRIVER_VERSION})"
  echo "Short ChromeDriver version -> "${CHROMEDRIVER_SHORT_VERSION}

  CHROME_TAGS=(
      ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-grid-${TAG_VERSION}
      # Browser version and browser driver version plus build date
      ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-${BUILD_DATE}
      # Browser version and browser driver version
      ${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}
      # Browser version and build date
      ${CHROME_VERSION}-${BUILD_DATE}
      # Browser version
      ${CHROME_VERSION}
      ## Short versions
      ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
      # Browser version and browser driver version plus build date
      ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}-${BUILD_DATE}
      # Browser version and browser driver version
      ${CHROME_SHORT_VERSION}-chromedriver-${CHROMEDRIVER_SHORT_VERSION}
      # Browser version and build date
      ${CHROME_SHORT_VERSION}-${BUILD_DATE}
      # Browser version
      ${CHROME_SHORT_VERSION}
  )

  for chrome_tag in "${CHROME_TAGS[@]}"
  do
    docker tag ${NAMESPACE}/node-chrome:${TAG_VERSION} ${NAMESPACE}/node-chrome:${chrome_tag}
    docker tag ${NAMESPACE}/standalone-chrome:${TAG_VERSION} ${NAMESPACE}/standalone-chrome:${chrome_tag}
    if [ "${PUSH_IMAGE}" = true ]; then
        docker push ${NAMESPACE}/node-chrome:${chrome_tag}
        docker push ${NAMESPACE}/standalone-chrome:${chrome_tag}
    fi
  done

  ;;
firefox)
  FIREFOX_VERSION=$(docker run --rm selenium/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
  echo "Firefox version -> "${FIREFOX_VERSION}
  FIREFOX_SHORT_VERSION="$(short_version ${FIREFOX_VERSION})"
  echo "Short Firefox version -> "${FIREFOX_SHORT_VERSION}
  GECKODRIVER_VERSION=$(docker run --rm selenium/node-firefox:${TAG_VERSION} geckodriver --version | awk 'NR==1{print $2}')
  echo "GeckoDriver version -> "${GECKODRIVER_VERSION}
  GECKODRIVER_SHORT_VERSION="$(short_version ${GECKODRIVER_VERSION})"
  echo "Short GeckoDriver version -> "${GECKODRIVER_SHORT_VERSION}

  FIREFOX_TAGS=(
      ${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}-grid-${TAG_VERSION}
      # Browser version and browser driver version plus build date
      ${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}-${BUILD_DATE}
      # Browser version and browser driver version
      ${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}
      # Browser version and build date
      ${FIREFOX_VERSION}-${BUILD_DATE}
      # Browser version
      ${FIREFOX_VERSION}
      ## Short versions
      ${FIREFOX_SHORT_VERSION}-geckodriver-${GECKODRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
      # Browser version and browser driver version plus build date
      ${FIREFOX_SHORT_VERSION}-geckodriver-${GECKODRIVER_SHORT_VERSION}-${BUILD_DATE}
      # Browser version and browser driver version
      ${FIREFOX_SHORT_VERSION}-geckodriver-${GECKODRIVER_SHORT_VERSION}
      # Browser version and build date
      ${FIREFOX_SHORT_VERSION}-${BUILD_DATE}
      # Browser version
      ${FIREFOX_SHORT_VERSION}
  )

  for firefox_tag in "${FIREFOX_TAGS[@]}"
  do
    docker tag ${NAMESPACE}/node-firefox:${TAG_VERSION} ${NAMESPACE}/node-firefox:${firefox_tag}
    docker tag ${NAMESPACE}/standalone-firefox:${TAG_VERSION} ${NAMESPACE}/standalone-firefox:${firefox_tag}
    if [ "${PUSH_IMAGE}" = true ]; then
        docker push ${NAMESPACE}/node-firefox:${firefox_tag}
        docker push ${NAMESPACE}/standalone-firefox:${firefox_tag}
    fi
  done

  ;;
opera)
  OPERA_VERSION=$(docker run --rm selenium/node-opera:${TAG_VERSION} opera --version)
  echo "Opera version -> "${OPERA_VERSION}
  OPERA_SHORT_VERSION="$(short_version ${OPERA_VERSION})"
  echo "Short Opera version -> "${OPERA_SHORT_VERSION}
  OPERADRIVER_VERSION=$(docker run --rm selenium/node-opera:${TAG_VERSION} operadriver --version | awk 'NR==1{print $2}')
  echo "OperaDriver version -> "${OPERADRIVER_VERSION}
  OPERADRIVER_SHORT_VERSION="$(short_version ${OPERADRIVER_VERSION})"
  echo "Short OperaDriver version -> "${OPERADRIVER_SHORT_VERSION}

  OPERA_TAGS=(
      ${OPERA_VERSION}-operadriver-${OPERADRIVER_VERSION}-grid-${TAG_VERSION}
      # Browser version and browser driver version plus build date
      ${OPERA_VERSION}-operadriver-${OPERADRIVER_VERSION}-${BUILD_DATE}
      # Browser version and browser driver version
      ${OPERA_VERSION}-operadriver-${OPERADRIVER_VERSION}
      # Browser version and build date
      ${OPERA_VERSION}-${BUILD_DATE}
      # Browser version
      ${OPERA_VERSION}
      ## Short versions
      ${OPERA_SHORT_VERSION}-operadriver-${OPERADRIVER_SHORT_VERSION}-grid-${TAG_VERSION}
      # Browser version and browser driver version plus build date
      ${OPERA_SHORT_VERSION}-operadriver-${OPERADRIVER_SHORT_VERSION}-${BUILD_DATE}
      # Browser version and browser driver version
      ${OPERA_SHORT_VERSION}-operadriver-${OPERADRIVER_SHORT_VERSION}
      # Browser version and build date
      ${OPERA_SHORT_VERSION}-${BUILD_DATE}
      # Browser version
      ${OPERA_SHORT_VERSION}
  )

  for opera_tag in "${OPERA_TAGS[@]}"
  do
    docker tag ${NAMESPACE}/node-opera:${TAG_VERSION} ${NAMESPACE}/node-opera:${opera_tag}
    docker tag ${NAMESPACE}/standalone-opera:${TAG_VERSION} ${NAMESPACE}/standalone-opera:${opera_tag}
    if [ "${PUSH_IMAGE}" = true ]; then
        docker push ${NAMESPACE}/node-opera:${opera_tag}
        docker push ${NAMESPACE}/standalone-opera:${opera_tag}
    fi
  done

  ;;
*)
  echo "Unknown browser!"
  ;;
esac
