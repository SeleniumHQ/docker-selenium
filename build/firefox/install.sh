#!/bin/bash
set -e
set -x

#=================
# Mozilla Firefox
#=================
apt-get update -qqy
apt-get -qqy --no-install-recommends install firefox

#========================
# Selenium Configuration
#========================
cp /tmp/build/firefox/config.json /opt/selenium/config.json
