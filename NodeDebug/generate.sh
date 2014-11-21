#!/bin/bash
FOLDER=../$1
BASE=$2
BROWSER=$3
VERSION=$4

rm -rf $FOLDER
mkdir -p $FOLDER

echo FROM selenium/$BASE:$VERSION > $FOLDER/Dockerfile
cat ./Dockerfile >> $FOLDER/Dockerfile

cat ../NodeBase/entry_point.sh \
  | sed 's/^xvfb-run/sudo -E -i -u seluser \\\
  DISPLAY=$DISPLAY \\\
  xvfb-run/' \
  | sed 's/^wait \$NODE_PID/sleep 0.5\
\
fluxbox -display $DISPLAY \&\
\
x11vnc -forever -usepw -shared -rfbport 5900 -display $DISPLAY \&\
\
wait \$NODE_PID/' \
  > $FOLDER/entry_point.sh

cat ./README.template.md \
  | sed "s/##BROWSER##/$BROWSER/" \
  | sed "s/##BASE##/$BASE/" \
  | sed "s/##FOLDER##/$1/" > $FOLDER/README.md

cp ./README-short.txt $FOLDER/README-short.txt
