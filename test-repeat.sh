#!/usr/bin/env bash
COUNTER=0

while [ $COUNTER -lt 50 ]; do
  echo The counter is $COUNTER
  let COUNTER=COUNTER+1
  docker run --rm -it --link $1:hub selenium/test:local node smoke-chrome.js
done
