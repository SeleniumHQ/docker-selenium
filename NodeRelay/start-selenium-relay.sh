#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Node Docker..."

if [[ -z "${SE_EVENT_BUS_HOST}" ]]; then
  echo "SE_EVENT_BUS_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_EVENT_BUS_PUBLISH_PORT}" ]]; then
  echo "SE_EVENT_BUS_PUBLISH_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_EVENT_BUS_SUBSCRIBE_PORT}" ]]; then
  echo "SE_EVENT_BUS_SUBSCRIBE_PORT not set, exiting!" 1>&2
  exit 1
fi

if [ "$GENERATE_CONFIG" = true ]; then
  echo "Generating Selenium Config"
  /opt/bin/generate_config
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_NODE_GRID_URL" ]; then
  echo "Appending Grid url: ${SE_NODE_GRID_URL}"
  SE_GRID_URL="--grid-url ${SE_NODE_GRID_URL}"
fi

echo "Selenium Grid Node configuration: "
cat "$CONFIG_FILE"
echo "Starting Selenium Grid Node..."

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar node \
  --bind-host ${SE_BIND_HOST} \
  --detect-drivers false \
  --config "$CONFIG_FILE" \
  ${SE_GRID_URL} ${SE_OPTS}
