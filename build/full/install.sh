#!/bin/bash
set -e
set -x

#========================
# Selenium Configuration
#========================
cp /tmp/build/full/config.json /opt/selenium/config.json

cp -rT /tmp/build/full/etc/ /etc/
