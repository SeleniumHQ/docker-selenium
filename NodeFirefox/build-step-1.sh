#!/bin/bash

BUILD_DATE=$(date +'%Y%m%d')
# Make sure other images are built first using build.sh
# We need both the Base and NodeBase to begin building NodeFirefox

# Install geckodriver binary dependencies
docker buildx build --platform linux/arm64 -f Dockerfile-geckodriver-arm64 -t local-seleniarm/geckodriver-arm64:4.0.0-$BUILD_DATE .

# build geckodriver binary and copy to build folder on host
echo 'Building geckodriver must be done manually from within an intermediate container. Run ./build-geckodriver-arm64.sh on the container, then exit...'
docker run --rm -it -v $PWD:/media/host -w /opt/geckodriver --name geckodriver-arm64 local-seleniarm/geckodriver-arm64:4.0.0-$BUILD_DATE bash


echo 'After exiting, run build-step-2.sh'
