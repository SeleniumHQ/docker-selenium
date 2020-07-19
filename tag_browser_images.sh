#!/usr/bin/env bash

TAG_VERSION=$1
NAMESPACE=$2
BROWSER=$3

echo "Tagging images for browser ${BROWSER}, tag version ${TAG_VERSION}, namespace ${NAMESPACE}"

case "${BROWSER}" in

chrome)
  CHROME_VERSION=$(docker run --rm selenium/node-chrome:${TAG_VERSION} google-chrome --version | awk '{print $3}')
  echo "Chrome version -> "${CHROME_VERSION}

  CHROMEDRIVER_VERSION=$(docker run --rm selenium/node-chrome:${TAG_VERSION} chromedriver --version | awk '{print $2}')
  echo "ChromeDriver version -> "${CHROMEDRIVER_VERSION}

  docker tag ${NAMESPACE}/node-chrome:${TAG_VERSION} \
      ${NAMESPACE}/node-chrome:${CHROME_VERSION}-chromedriver-${CHROMEDRIVER_VERSION}-grid-${TAG_VERSION}
  ;;
firefox)
  FIREFOX_VERSION=$(docker run --rm selenium/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
  echo "Firefox version -> "${FIREFOX_VERSION}

  GECKODRIVER_VERSION=$(docker run --rm selenium/node-firefox:${TAG_VERSION} geckodriver --version | awk 'NR==1{print $2}')
  echo "GeckoDriver version -> "${GECKODRIVER_VERSION}

  docker tag ${NAMESPACE}/node-firefox:${TAG_VERSION} \
      ${NAMESPACE}/node-firefox:${FIREFOX_VERSION}-geckodriver-${GECKODRIVER_VERSION}-grid-${TAG_VERSION}
  ;;
opera)
  OPERA_VERSION=$(docker run --rm selenium/node-opera:${TAG_VERSION} opera --version)
  echo "Opera version -> "${OPERA_VERSION}

  OPERADRIVER_VERSION=$(docker run --rm selenium/node-opera:${TAG_VERSION} operadriver --version | awk 'NR==1{print $2}')
  echo "OperaDriver version -> "${OPERADRIVER_VERSION}

  docker tag ${NAMESPACE}/node-opera:${TAG_VERSION} \
      ${NAMESPACE}/node-opera:${OPERA_VERSION}-operadriver-${OPERADRIVER_VERSION}-grid-${TAG_VERSION}
  ;;
*)
  echo "Unknown browser!"
  ;;
esac
