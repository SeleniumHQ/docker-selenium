#!/bin/bash

DOCKERDEB=false   # if using Docker Desktop, set to false
ARCH=linux/amd64

if [[ $DOCKERDEB == true ]]
then
    echo 'Getting geckodriver binary from the Docker Debian VM...'
    sh get-geckodriver.sh
else
    echo 'Getting geckodriver from /media/host...'
    cp /media/host/geckodriver .
fi

echo 'Generate the Dockerfile.arm64...'
BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.1.0
NAMESPACE=local-seleniarm
AUTHORS=SeleniumHQ,sj26,jamesmortensen

echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" > ./Dockerfile
echo "# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED." >> ./Dockerfile
echo "# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE" >> ./Dockerfile
echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> ./Dockerfile
echo FROM ${NAMESPACE}/node-base:${VERSION}-${BUILD_DATE} >> ./Dockerfile
echo LABEL authors="$AUTHORS" >> ./Dockerfile
echo "" >> ./Dockerfile
cat ./Dockerfile.arm64 >> ./Dockerfile



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
