NAME="${NAME:-jamesmortensen1}"
VERSION="${VERSION:-4.7.2}"
BUILD_DATE="${BUILD_DATE:-$(date '+%Y%m%d')}"
PLATFORMS="${PLATFORMS:-linux/arm64,linux/arm/v7,linux/amd64}"
BUILD_ARGS=--push

FROM_IMAGE_ARGS="--build-arg NAMESPACE=$NAME --build-arg VERSION=$VERSION-$BUILD_DATE"
TAG_VERSION=$VERSION-$BUILD_DATE

START=$(date +'%s')
echo $START

if [ "$1" = "base_multi" ]; then
    #cd ./Base && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} -t ${NAME}/base:${TAG_VERSION} .
    make base_multi

elif [ "$1" = "grid_multi" ]; then
    cd ./Hub && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/hub:${TAG_VERSION} .
    cd ../NodeDocker && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/node-docker:${TAG_VERSION} .
    cd ../StandaloneDocker && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/standalone-docker:${TAG_VERSION} .
    cd ../Sessions && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/sessions:${TAG_VERSION} .
    cd ../SessionQueue && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/session-queue:${TAG_VERSION} .
    cd ../EventBus && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/event-bus:${TAG_VERSION} .
    cd ../Router && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/router:${TAG_VERSION} .
    cd ../Distributor && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/distributor:${TAG_VERSION} .
elif [ "$1" = "node_base_multi" ]; then
    cd ./NodeBase && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/node-base:${TAG_VERSION} .

elif [ "$1" = "firefox_multi" ]; then
    FROM_IMAGE_ARGS="$FROM_IMAGE_ARGS --build-arg BASE=node-firefox"
    cd ./NodeFirefox && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -f Dockerfile.multi-arch -t ${NAME}/node-firefox:${TAG_VERSION} .
    cd ../Standalone && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/standalone-firefox:${TAG_VERSION} .

elif [ "$1" = "chromium_multi" ]; then
    FROM_IMAGE_ARGS="$FROM_IMAGE_ARGS --build-arg BASE=node-chromium"
    cd ./NodeChromium && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/node-chromium:${TAG_VERSION} .
    cd ../Standalone && docker buildx build --platform ${PLATFORMS} ${BUILD_ARGS} ${FROM_IMAGE_ARGS} -t ${NAME}/standalone-chromium:${TAG_VERSION} .

else
    echo "Not found. Options are 'base', 'grid', 'node-base', 'firefox', and 'chromium'"
fi

STOP=$(date +'%s')
echo $(( $STOP - $START )) seconds
