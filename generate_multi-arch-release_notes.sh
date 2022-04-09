#!/usr/bin/env bash

LATEST_TAG=$1
HEAD_BRANCH=$2
GRID_VERSION=$3
BUILD_DATE=$4

TAG_VERSION=${GRID_VERSION}-${BUILD_DATE}

echo "" >> release_notes.md
echo "### Changelog" > release_notes.md
git --no-pager log "${LATEST_TAG}...${HEAD_BRANCH}" --pretty=format:"* [\`%h\`](http://github.com/seleniumhq-community/docker-seleniarm/commit/%H) - %s :: %an" --reverse >> release_notes.md

CHROMIUM_VERSION=$(docker run --rm seleniarm/node-chromium:${TAG_VERSION} chromium --version | awk '{print $2}')
CHROMEDRIVER_VERSION=$(docker run --rm seleniarm/node-chromium:${TAG_VERSION} chromedriver --version | awk '{print $2}')
FIREFOX_VERSION=$(docker run --rm seleniarm/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
GECKODRIVER_VERSION=$(docker run --rm seleniarm/node-firefox:${TAG_VERSION} geckodriver --version | awk 'NR==1{print $2}')



echo "" >> release_notes.md
echo "### Released versions" >> release_notes.md
echo "* Selenium: ${GRID_VERSION}" >> release_notes.md
echo "* Chromium: ${CHROMIUM_VERSION}" >> release_notes.md
echo "* ChromiumDriver: ${CHROMEDRIVER_VERSION}" >> release_notes.md
echo "* Firefox: ${FIREFOX_VERSION}" >> release_notes.md
echo "* GeckoDriver: ${GECKODRIVER_VERSION}" >> release_notes.md

echo "" >> release_notes.md
echo "### Published Docker images" >> release_notes.md
echo "<details>" >> release_notes.md
echo "<summary>Click to see published Docker images</summary>" >> release_notes.md
echo "" >> release_notes.md
echo '```' >> release_notes.md
docker images --filter=reference='seleniarm/*:*' --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" >> release_notes.md
echo '```' >> release_notes.md
echo "" >> release_notes.md
echo "</details>" >> release_notes.md

