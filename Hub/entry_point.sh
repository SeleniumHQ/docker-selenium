#!/bin/bash

ROOT=/opt/selenium
CONF=$ROOT/config.json

$ROOT/generate_config >$CONF
echo "starting selenium hub with configuration:"
cat $CONF

java -jar /opt/selenium/selenium-server-standalone.jar \
  -role hub \
  -hubConfig $CONF

