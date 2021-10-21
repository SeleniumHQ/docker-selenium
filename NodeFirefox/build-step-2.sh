#!/bin/bash

BUILD_DATE=$(date +'%Y%m%d')
DOCKERDEB=false   # if using Docker Desktop, set to false

if [[ $DOCKERDEB == true ]]
then
    echo 'Getting geckodriver binary from the Docker Debian VM...'
    sh get-geckodriver.sh
else
    echo 'Getting geckodriver from /media/host...'
    cp /media/host/geckodriver .
fi


echo 'Building Seleniarm/NodeFirefox:4.0.0-$BUILD_DATE'
docker buildx build --platform linux/arm64 -f Dockerfile.arm64 -t local-seleniarm/node-firefox:4.0.0-$BUILD_DATE .
docker tag local-seleniarm/node-firefox:4.0.0-$BUILD_DATE local-seleniarm/node-firefox:latest

# Generate the Seleniarm/StandaloneFirefox Dockerfile
cd ../Standalone && sh generate.sh StandaloneFirefox node-firefox 4.0.0-$BUILD_DATE local-seleniarm SeleniumHQ,sj26,james
cd ../StandaloneFirefox

echo 'Building Seleniarm/StandaloneFirefox:4.0.0-$BUILD_DATE'
docker buildx build --platform linux/arm64 -f Dockerfile -t local-seleniarm/standalone-firefox:4.0.0-$BUILD_DATE .
docker tag local-seleniarm/standalone-firefox:4.0.0-$BUILD_DATE local-seleniarm/standalone-firefox:latest


# Remove geckodriver image and dependencies if build is successful, since it's 4.9GB!
docker image rm local-seleniarm/geckodriver-arm64:4.0.0-$BUILD_DATE
