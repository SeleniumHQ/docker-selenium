#!/bin/bash
VERSION=$1
NAMESPACE=$2
AUTHORS=$3

echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" > ./Dockerfile
echo "# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED." >> ./Dockerfile
echo "# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE" >> ./Dockerfile
echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> ./Dockerfile
echo "FROM ubuntu:bionic AS builder-codecs-ffmpeg" >> ./Dockerfile
echo "RUN apt-get update -qqy && apt-get -qqy install chromium-codecs-ffmpeg-extra" >> ./Dockerfile
echo "" >> ./Dockerfile
echo FROM ${NAMESPACE}/node-base:${VERSION} >> ./Dockerfile
echo LABEL authors="$AUTHORS" >> ./Dockerfile
echo "" >> ./Dockerfile
cat ./Dockerfile.txt >> ./Dockerfile
