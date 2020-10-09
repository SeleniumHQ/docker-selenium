#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Standalone Docker..."

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar standalone \
  --relax-checks true \
  --detect-drivers false \
  --config /opt/bin/config.toml \
  ${SE_OPTS}
