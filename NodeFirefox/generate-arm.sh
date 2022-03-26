#!/bin/bash
echo 'Generate the Dockerfile.arm64...'
BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.1.2
TAG_VERSION=${1:-$VERSION-$BUILD_DATE}
NAMESPACE="${2:-local-seleniarm}"
AUTHORS="${3:-SeleniumHQ,sj26,jamesmortensen}"

echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" > ./Dockerfile
echo "# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED." >> ./Dockerfile
echo "# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE" >> ./Dockerfile
echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> ./Dockerfile
#echo FROM ${NAMESPACE}/node-base:${VERSION}-${BUILD_DATE} >> ./Dockerfile
echo FROM ${NAMESPACE}/node-base:${TAG_VERSION} >> ./Dockerfile
echo LABEL authors="$AUTHORS" >> ./Dockerfile
echo "" >> ./Dockerfile
cat ./Dockerfile.arm64 >> ./Dockerfile

