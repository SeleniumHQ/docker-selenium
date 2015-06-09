#!/bin/bash
VERSION=$1

echo FROM selenium/base:$VERSION > ./Dockerfile
cat ./Dockerfile.txt >> ./Dockerfile
