#!/bin/bash
FOLDER=../$1
BASE=$2
BROWSER=$3
VERSION=$4
NAMESPACE=$5
AUTHORS=$6

echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" > $FOLDER/Dockerfile
echo "# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED." >> $FOLDER/Dockerfile
echo "# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE" >> $FOLDER/Dockerfile
echo "# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> $FOLDER/Dockerfile
echo FROM $NAMESPACE/$BASE:$VERSION >> $FOLDER/Dockerfile
echo LABEL authors="$AUTHORS" >> $FOLDER/Dockerfile
echo "" >> $FOLDER/Dockerfile
cat ./Dockerfile.txt >> $FOLDER/Dockerfile

cat ./README.template.md \
  | sed "s/##BROWSER##/$BROWSER/" \
  | sed "s/##BASE##/$BASE/" \
  | sed "s/##FOLDER##/$1/" > $FOLDER/README.md

cp ./README-short.txt $FOLDER/README-short.txt
cp ./entry_point.sh $FOLDER/entry_point.sh
