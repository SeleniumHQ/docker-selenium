#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid SessionQueuer..."

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

if [ ! -z "$SE_SESSION_QUEUER_HOST" ]; then
  echo "Using SE_SESSION_QUEUER_HOST: ${SE_SESSION_QUEUER_HOST}"
  HOST_CONFIG="--host ${SE_SESSION_QUEUER_HOST}"
fi

if [ ! -z "$SE_SESSION_QUEUER_PORT" ]; then
  echo "Using SE_SESSION_QUEUER_PORT: ${SE_SESSION_QUEUER_PORT}"
  PORT_CONFIG="--port ${SE_SESSION_QUEUER_PORT}"
fi

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar sessionqueuer \
  --publish-events tcp://"${SE_EVENT_BUS_HOST}":${SE_EVENT_BUS_PUBLISH_PORT} \
  --subscribe-events tcp://"${SE_EVENT_BUS_HOST}":${SE_EVENT_BUS_SUBSCRIBE_PORT} \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SE_OPTS}
