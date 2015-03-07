#!/bin/bash
FOLDER=../$1
BASE=$2
BROWSER=$3
VERSION=$4

rm -rf $FOLDER
mkdir -p $FOLDER

echo FROM selenium/$BASE:$VERSION > $FOLDER/Dockerfile
cat ../NodeDebug/Dockerfile >> $FOLDER/Dockerfile

cp ./entry_point.sh $FOLDER
