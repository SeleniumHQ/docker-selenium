#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Standalone Docker..."

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_NODE_GRID_URL" ]; then
  echo "Appending Grid url: ${SE_NODE_GRID_URL}"
  SE_GRID_URL="--grid-url ${SE_NODE_GRID_URL}"
fi

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar standalone \
  --relax-checks ${SE_RELAX_CHECKS} \
  --detect-drivers false \
  --bind-host ${SE_BIND_HOST} \
  --config /opt/bin/config.toml \
  ${SE_GRID_URL} ${SE_OPTS}
