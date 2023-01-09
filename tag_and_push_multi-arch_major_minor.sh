#!/usr/bin/env bash

VERSION=$1
BUILD_DATE=$2
NAMESPACE=$3
PUSH_IMAGE="${4:-false}"
IMAGE=$5

TAG_VERSION=${VERSION}-${BUILD_DATE}

MAJOR=$(cut -d. -f1 <<<"${VERSION}")
MAJOR_MINOR=$(cut -d. -f1-2 <<<"${VERSION}")

TAGS=(
    $MAJOR
    $MAJOR_MINOR
    $VERSION
)

for tag in "${TAGS[@]}"
  do
    if [ "${PUSH_IMAGE}" = true ]; then
        sh tag-and-push-multi-arch-image.sh $VERSION $BUILD_DATE $NAMESPACE $IMAGE ${tag}
    fi
  done
