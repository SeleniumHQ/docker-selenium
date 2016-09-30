#!/bin/bash
FOLDER=../$1
BASE=$2
BROWSER=$3
VERSION=$4

echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" > $FOLDER/Dockerfile
echo "# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED." >> $FOLDER/Dockerfile
echo "# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE" >> $FOLDER/Dockerfile
echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> $FOLDER/Dockerfile
echo FROM selenium/$BASE:$VERSION >> $FOLDER/Dockerfile
cat ./Dockerfile.txt >> $FOLDER/Dockerfile

cat ../NodeBase/entry_point.sh \
  | sed 's/^xvfb-run/env | cut -f 1 -d "=" | sort > asroot\
  sudo -E -u seluser -i env | cut -f 1 -d "=" | sort > asseluser\
  sudo -E -i -u seluser \\\
  $(for E in $(grep -vxFf asseluser asroot); do echo $E=$(eval echo \\\$$E); done) \\\
  DISPLAY=$DISPLAY \\\
  xvfb-run/' \
  | sed 's/^wait \$NODE_PID/for i in $(seq 1 10)\
do\
  xdpyinfo -display $DISPLAY >\/dev\/null 2>\&1\
  if [ $? -eq 0 ]; then\
    break\
  fi\
  echo Waiting xvfb...\
  sleep 0.5\
done\
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
