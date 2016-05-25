#!/bin/bash
VERSION=$1

echo FROM selenium/node-base:$VERSION > ./Dockerfile
cat ./Dockerfile.txt >> ./Dockerfile
