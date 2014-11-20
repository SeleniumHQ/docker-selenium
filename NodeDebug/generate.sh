#!/bin/bash
FOLDER=../$1
BASE=$2
VERSION=$3

rm -rf $FOLDER
mkdir -p $FOLDER

echo FROM selenium/$BASE:$VERSION > $FOLDER/Dockerfile
cat ./Dockerfile >> $FOLDER/Dockerfile

sed '${s/$/ \\/;}' ../NodeBase/entry_point.sh > $FOLDER/entry_point.sh

sed 's/^xvfb-run/sudo -E -i -u seluser \\\
  DISPLAY=$DISPLAY \\\
  xvfb-run/' $FOLDER/entry_point.sh > $FOLDER/entry_point.sh.tmp
mv $FOLDER/entry_point.sh.tmp $FOLDER/entry_point.sh

cat ./debug-script.sh >> $FOLDER/entry_point.sh
