#!/bin/bash -x

BUILD_DATE=$(date +'%Y%m%d')
VERSION="${VERSION:-4.1.2}"
NAMESPACE="${NAMESPACE:-local-seleniarm}"
AUTHORS=SeleniumHQ,sj26,jamesmortensen

if [ "$1" == "arm64" ] || [ "$1" == "amd64" ] || [ "$1" == "arm/v7" ]; then
   echo "Building images for platform $1"
   PLATFORM=linux/$1
else
   echo "Run build.sh script as one of the following options:"
   echo ""
   echo "sh build.sh arm64"
   echo "sh build.sh arm/v7"
   echo "sh build.sh amd64"
   exit;
fi


cd ./Base && docker buildx build --platform $PLATFORM -t $NAMESPACE/base:$VERSION-$BUILD_DATE .
echo $PWD
cd ../Hub && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/hub:$VERSION-$BUILD_DATE .

cd ../NodeBase && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/node-base:$VERSION-$BUILD_DATE .
cd ../NodeChromium && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE .
cd ../NodeFirefox && sh generate-arm.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/node-firefox:$VERSION-$BUILD_DATE .

cd ../Standalone && sh generate.sh StandaloneChromium node-chromium $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && cd ../StandaloneChromium \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE .

cd ../Standalone && sh generate.sh StandaloneFirefox node-firefox $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && cd ../StandaloneFirefox \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/standalone-firefox:$VERSION-$BUILD_DATE .

cd ..

echo "Build base, node-base, hub, node-chromium, node-firefox, standalone-chromium, and standalone-firefox...\n"
echo "Tagging builds...\n"

docker tag $NAMESPACE/base:$VERSION-$BUILD_DATE $NAMESPACE/base:latest
docker tag $NAMESPACE/hub:$VERSION-$BUILD_DATE $NAMESPACE/hub:latest
docker tag $NAMESPACE/node-base:$VERSION-$BUILD_DATE $NAMESPACE/node-base:latest
docker tag $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE $NAMESPACE/node-chromium:latest
docker tag $NAMESPACE/node-firefox:$VERSION-$BUILD_DATE $NAMESPACE/node-firefox:latest
docker tag $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE $NAMESPACE/standalone-chromium:latest
docker tag $NAMESPACE/standalone-firefox:$VERSION-$BUILD_DATE $NAMESPACE/standalone-firefox:latest

echo "Testing the images...\n"
USE_RANDOM_USER_ID=false VERSION=$VERSION BUILD_DATE=$BUILD_DATE NAME=$NAMESPACE SKIP_BUILD=true make test_multi_arch

