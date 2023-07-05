#!/usr/bin/env bash

LATEST_TAG=$1
HEAD_BRANCH=$2
GRID_VERSION=$3
BUILD_DATE=$4

NAMESPACE="${NAMESPACE:-seleniarm}"
TAG_VERSION=${GRID_VERSION}-${BUILD_DATE}

echo "" >> release_notes.md
echo "### Changelog" > release_notes.md
git --no-pager log "${LATEST_TAG}...${HEAD_BRANCH}" --pretty=format:"* [\`%h\`](http://github.com/seleniumhq-community/docker-seleniarm/commit/%H) - %s :: %an" --reverse >> release_notes.md

##############################################################
# Pull the images so we can populate the release notes
# We'll pull using the TAG_VERSION and then add the other
# related tags separately to avoid exceeding the rate limits.
##############################################################
docker pull ${NAMESPACE}/base:${TAG_VERSION}
docker pull ${NAMESPACE}/hub:${TAG_VERSION}
docker pull ${NAMESPACE}/node-base:${TAG_VERSION}
docker pull ${NAMESPACE}/standalone-chromium:${TAG_VERSION}
docker pull ${NAMESPACE}/standalone-firefox:${TAG_VERSION}

docker pull ${NAMESPACE}/node-chromium:${TAG_VERSION}
docker pull ${NAMESPACE}/node-firefox:${TAG_VERSION}
docker pull ${NAMESPACE}/node-docker:${TAG_VERSION}
docker pull ${NAMESPACE}/standalone-docker:${TAG_VERSION}
docker pull ${NAMESPACE}/sessions:${TAG_VERSION}
docker pull ${NAMESPACE}/session-queue:${TAG_VERSION}
docker pull ${NAMESPACE}/event-bus:${TAG_VERSION}
docker pull ${NAMESPACE}/router:${TAG_VERSION}
docker pull ${NAMESPACE}/distributor:${TAG_VERSION}

######################################################################
# Tags are already pushed to Docker Hub, but we need them set locally
# to generate release notes. Since we know the tags, we can set
# them locally to avoid exceeding the docker pull rate-limit.
######################################################################
bash docker-add-related-tags.sh base ${TAG_VERSION}
bash docker-add-related-tags.sh hub ${TAG_VERSION}
bash docker-add-related-tags.sh node-base ${TAG_VERSION}
bash docker-add-related-tags.sh standalone-chromium ${TAG_VERSION}
bash docker-add-related-tags.sh standalone-firefox ${TAG_VERSION}
bash docker-add-related-tags.sh node-chromium ${TAG_VERSION}
bash docker-add-related-tags.sh node-firefox ${TAG_VERSION}
bash docker-add-related-tags.sh node-docker ${TAG_VERSION}
bash docker-add-related-tags.sh standalone-docker ${TAG_VERSION}
bash docker-add-related-tags.sh sessions ${TAG_VERSION}
bash docker-add-related-tags.sh session-queue ${TAG_VERSION}
bash docker-add-related-tags.sh event-bus ${TAG_VERSION}
bash docker-add-related-tags.sh router ${TAG_VERSION}
bash docker-add-related-tags.sh distributor ${TAG_VERSION}

CHROMIUM_VERSION=$(docker run --rm ${NAMESPACE}/node-chromium:${TAG_VERSION} chromium --version | awk '{print $2}')
CHROMEDRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-chromium:${TAG_VERSION} chromedriver --version | awk '{print $2}')
FIREFOX_VERSION=$(docker run --rm ${NAMESPACE}/node-firefox:${TAG_VERSION} firefox --version | awk '{print $3}')
GECKODRIVER_VERSION=$(docker run --rm ${NAMESPACE}/node-firefox:${TAG_VERSION} geckodriver --version | awk 'NR==1{print $2}')

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
docker images --filter=reference="seleniarm/*:*" --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" >> release_notes.md
echo '```' >> release_notes.md
echo "" >> release_notes.md
echo "</details>" >> release_notes.md
