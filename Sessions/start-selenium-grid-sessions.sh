#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Sessions..."

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

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

java "${JAVA_OPTS}" -jar /opt/selenium/selenium-server.jar sessions \
  --publish-events tcp://"${SE_EVENT_BUS_HOST}":"${SE_EVENT_BUS_PUBLISH_PORT}" \
  --subscribe-events tcp://"${SE_EVENT_BUS_HOST}":"${SE_EVENT_BUS_SUBSCRIBE_PORT}" \
  "${SE_OPTS}"
