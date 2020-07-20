#!/usr/bin/env bash

VERSION=$1
BUILD_DATE=$2
NAMESPACE=$3
BROWSER=$4

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
  echo "Short Chrome version -> "${CHROME_VERSION}

  CHROMEDRIVER_VERSION=$(docker run --rm selenium/node-chrome:${TAG_VERSION} chromedriver --version | awk '{print $2}')
  echo "ChromeDriver version -> "${CHROMEDRIVER_VERSION}
  CHROMEDRIVER_SHORT_VERSION="$(short_version ${CHROMEDRIVER_VERSION})"
  echo "Short ChromeDriver version -> "${CHROMEDRIVER_VERSION}

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
    docker tag ${NAMESPACE}/standalone-chrome:${TAG_VERSION} ${NAMESPACE}/node-chrome:${chrome_tag}
  done

  ;;
firefox)
  FIREFOX_VERSION=$(docker run --rm selenium/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
  echo "Firefox version -> "${FIREFOX_VERSION}

  GECKODRIVER_VERSION=$(docker run --rm selenium/node-firefox:${TAG_VERSION} geckodriver --version | awk 'NR==1{print $2}')
  echo "GeckoDriver version -> "${GECKODRIVER_VERSION}

  # Very verbose tag
  docker tag ${NAMESPACE}/node-firefox:${TAG_VERSION} \
      ${NAMESPACE}/node-firefox:${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}-grid-${TAG_VERSION}
  docker tag ${NAMESPACE}/standalone-firefox:${TAG_VERSION} \
      ${NAMESPACE}/standalone-firefox:${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}-grid-${TAG_VERSION}
  ;;
opera)
  OPERA_VERSION=$(docker run --rm selenium/node-opera:${TAG_VERSION} opera --version)
  echo "Opera version -> "${OPERA_VERSION}

  OPERADRIVER_VERSION=$(docker run --rm selenium/node-opera:${TAG_VERSION} operadriver --version | awk 'NR==1{print $2}')
  echo "OperaDriver version -> "${OPERADRIVER_VERSION}

  # Very verbose tag
  docker tag ${NAMESPACE}/node-opera:${TAG_VERSION} \
      ${NAMESPACE}/node-opera:${OPERA_VERSION}-operadriver-${OPERADRIVER_VERSION}-grid-${TAG_VERSION}
  docker tag ${NAMESPACE}/standalone-opera:${TAG_VERSION} \
      ${NAMESPACE}/standalone-opera:${OPERA_VERSION}-operadriver-${OPERADRIVER_VERSION}-grid-${TAG_VERSION}
  ;;
*)
  echo "Unknown browser!"
  ;;
esac
