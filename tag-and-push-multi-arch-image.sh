#!/bin/bash

VERSION=$1
BUILD_DATE=$2
NAMESPACE="${3:-seleniarm}"
IMAGE=$4
NEW_TAG=$5

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
  echo "Be sure to pass in all of the values"
  exit 1
fi


AMD64_DIGEST=`go run get-image-sha256-digest.go https://hub.docker.com/v2/repositories/$NAMESPACE/$IMAGE/tags/$VERSION-$BUILD_DATE/ | grep -w "amd64" | awk '{print $2}'`
ARM_DIGEST=`go run get-image-sha256-digest.go https://hub.docker.com/v2/repositories/$NAMESPACE/$IMAGE/tags/$VERSION-$BUILD_DATE/ | grep -w "arm" | awk '{print $2}'`
ARM64_DIGEST=`go run get-image-sha256-digest.go https://hub.docker.com/v2/repositories/$NAMESPACE/$IMAGE/tags/$VERSION-$BUILD_DATE/ | grep -w "arm64" | awk '{print $2}'`

docker manifest create $NAMESPACE/$IMAGE:$NEW_TAG \
  --amend $NAMESPACE/$IMAGE@$AMD64_DIGEST \
  --amend $NAMESPACE/$IMAGE@$ARM_DIGEST \
  --amend $NAMESPACE/$IMAGE@$ARM64_DIGEST

docker manifest push $NAMESPACE/$IMAGE:$NEW_TAG

