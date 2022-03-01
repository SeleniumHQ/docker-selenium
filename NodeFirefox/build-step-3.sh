#!/bin/sh
BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.1.2
NAMESPACE=local-seleniarm
AUTHORS=SeleniumHQ,sj26,jamesmortensen
ARCH=linux/arm64

echo "Building Seleniarm/NodeFirefox:$VERSION-$BUILD_DATE"
docker buildx build --platform $ARCH -f Dockerfile -t local-seleniarm/node-firefox:$VERSION-$BUILD_DATE .
docker tag local-seleniarm/node-firefox:$VERSION-$BUILD_DATE local-seleniarm/node-firefox:latest

# Generate the Seleniarm/StandaloneFirefox Dockerfile
cd ../Standalone && sh generate.sh StandaloneFirefox node-firefox $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS
cd ../StandaloneFirefox

echo "Building Seleniarm/StandaloneFirefox:$VERSION-$BUILD_DATE"
docker buildx build --platform $ARCH -f Dockerfile -t local-seleniarm/standalone-firefox:$VERSION-$BUILD_DATE .
docker tag local-seleniarm/standalone-firefox:$VERSION-$BUILD_DATE local-seleniarm/standalone-firefox:latest


# Remove geckodriver image and dependencies if build is successful, since it's 4.9GB!
docker image rm local-seleniarm/geckodriver-arm64:$VERSION-$BUILD_DATE
