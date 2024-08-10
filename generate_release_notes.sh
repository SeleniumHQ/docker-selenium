#!/usr/bin/env bash

LATEST_TAG=$1
HEAD_BRANCH=$2
GRID_VERSION=$3
BUILD_DATE=$4
NAMESPACE=${NAME:-selenium}
FFMPEG_TAG_VERSION=$(grep FFMPEG_TAG_VERSION Makefile | sed 's/.*,\([^)]*\))/\1/p' | head -n 1)
RCLONE_TAG_VERSION=$(grep RCLONE_TAG_VERSION Makefile | sed 's/.*,\([^)]*\))/\1/p' | head -n 1)

TAG_VERSION=${GRID_VERSION}-${BUILD_DATE}

echo "" >> release_notes.md
echo "### Changelog" > release_notes.md
git --no-pager log "${LATEST_TAG}...${HEAD_BRANCH}" --pretty=format:"* [\`%h\`](http://github.com/seleniumhq/docker-selenium/commit/%H) - %s :: %an" --reverse >> release_notes.md

CHROME_VERSION=$(docker run --rm ${NAMESPACE}/node-chrome:${TAG_VERSION} google-chrome --version | awk '{print $3}')
EDGE_VERSION=$(docker run --rm ${NAMESPACE}/node-edge:${TAG_VERSION} microsoft-edge --version | awk '{print $3}')
CHROMEDRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-chrome:${TAG_VERSION} chromedriver --version | awk '{print $2}')
EDGEDRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-edge:${TAG_VERSION} msedgedriver --version | awk '{print $4}')
FIREFOX_VERSION=$(docker run --rm ${NAMESPACE}/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
GECKODRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-firefox:${TAG_VERSION} geckodriver --version | awk 'NR==1{print $2}')
FFMPEG_VERSION=$(docker run --entrypoint="" --rm ${NAMESPACE}/video:${FFMPEG_TAG_VERSION}-${BUILD_DATE} ffmpeg -version | awk '{print $3}' | head -n 1)
RCLONE_VERSION=$(docker run --entrypoint="" --rm ${NAMESPACE}/video:${FFMPEG_TAG_VERSION}-${BUILD_DATE} rclone version | head -n 1 | awk '{print $2}' | tr -d 'v')
JRE_VERSION=$(docker run --entrypoint="" --rm ${NAMESPACE}/base:${TAG_VERSION} java --version | grep -oP '\b\d+\.\d+\.\d+\b' | head -1)
FIREFOX_ARM64_VERSION=$(docker run --rm --platform linux/arm64 ${NAMESPACE}/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
CHROMIUM_VERSION=$(docker run --rm ${NAMESPACE}/node-chromium:${TAG_VERSION} chromium --version | awk '{print $2}')
CHROMIUMDRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-chromium:${TAG_VERSION} chromedriver --version | awk '{print $2}')


echo "" >> release_notes.md
echo "### Released versions" >> release_notes.md
echo "| Components | x86_64 (amd64) | aarch64 (arm64/armv8) |" >> release_notes.md
echo "|:----------:|:--------------:|:---------------------:|" >> release_notes.md
echo "| Selenium | ${GRID_VERSION} | ${GRID_VERSION} |" >> release_notes.md
echo "| Chromium | ${CHROMIUM_VERSION} | ${CHROMIUM_VERSION} |" >> release_notes.md
echo "| Chrome | ${CHROME_VERSION} | x |" >> release_notes.md
echo "| ChromeDriver | ${CHROMEDRIVER_VERSION} | ${CHROMIUMDRIVER_VERSION} |" >> release_notes.md
echo "| Edge | ${EDGE_VERSION} | x |" >> release_notes.md
echo "| EdgeDriver | ${EDGEDRIVER_VERSION} | x |" >> release_notes.md
echo "| Firefox | ${FIREFOX_VERSION} | ${FIREFOX_ARM64_VERSION} |" >> release_notes.md
echo "| GeckoDriver | ${GECKODRIVER_VERSION} | ${GECKODRIVER_VERSION} |" >> release_notes.md
echo "| ffmpeg | ${FFMPEG_VERSION} | ${FFMPEG_VERSION} |" >> release_notes.md
echo "| rclone | ${RCLONE_VERSION} | ${RCLONE_VERSION} |" >> release_notes.md
echo "| Java Runtime | ${JRE_VERSION} | ${JRE_VERSION} |" >> release_notes.md

echo "" >> release_notes.md
echo "### Published Docker images on [Docker Hub](https://hub.docker.com/u/${NAMESPACE})" >> release_notes.md
echo "<details>" >> release_notes.md
echo "<summary>Click to see published Docker images</summary>" >> release_notes.md
echo "" >> release_notes.md
echo '```' >> release_notes.md
docker images --filter=reference=${NAMESPACE}'/*:'${FILTER_IMAGE_TAG:-"*"} --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" >> release_notes.md
echo '```' >> release_notes.md
echo "" >> release_notes.md
echo "</details>" >> release_notes.md

echo "" >> release_notes.md
chart_version=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 cat | grep ^version | cut -d ':' -f 2 | tr -d '[:space:]')
echo "### Published Helm chart version [selenium-grid-${chart_version}](https://github.com/${AUTHORS:-"SeleniumHQ"}/docker-selenium/releases/tag/selenium-grid-${chart_version})" >> release_notes.md
