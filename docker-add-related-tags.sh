#!/bin/bash

NAMESPACE=${NAMESPACE:-seleniarm}
IMAGE=$1
TAG=$2
NO_PULL=$3

echo $NAMESPACE $IMAGE $TAG

RELATED_TAGS=(`go run get-related-tags.go https://hub.docker.com/v2/repositories/$NAMESPACE/$IMAGE/tags/$TAG | tail -n 1`)

for related_tag in "${RELATED_TAGS[@]}"
  do
    echo Add tag $NAMESPACE/$IMAGE:${related_tag}
    docker tag $NAMESPACE/$IMAGE:$TAG $NAMESPACE/$IMAGE:$related_tag
  done

