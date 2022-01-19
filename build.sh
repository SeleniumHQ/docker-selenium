#!/bin/bash -x

BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.1.1
CHROMIUM=93.0.4577.82  # Not yet used at this time. Edit in NodeChromium/Dockerfile.txt
NAMESPACE=local-seleniarm
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
# && sed 's/chromium=.*/chromium=91.0.4472.124/' Dockerfile > Dockerfile \
cd ../NodeChromium && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE .

cd ../Standalone && sh generate.sh StandaloneChromium node-chromium $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && cd ../StandaloneChromium \
   && docker buildx build --platform $PLATFORM -t $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE .

echo "Build node-hub, node-chromium, and standalone-chromium...\n"
echo "Tagging builds...\n"

docker tag $NAMESPACE/base:$VERSION-$BUILD_DATE $NAMESPACE/base:latest
docker tag $NAMESPACE/hub:$VERSION-$BUILD_DATE $NAMESPACE/hub:latest
docker tag $NAMESPACE/node-base:$VERSION-$BUILD_DATE $NAMESPACE/node-base:latest
docker tag $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE $NAMESPACE/node-chromium:latest
docker tag $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE $NAMESPACE/standalone-chromium:latest

