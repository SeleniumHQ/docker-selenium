#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Distributor..."

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

if [[ -z "${SE_SESSIONS_MAP_HOST}" ]]; then
  echo "SE_SESSIONS_MAP_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSIONS_MAP_PORT}" ]]; then
  echo "SE_SESSIONS_MAP_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUE_HOST}" ]]; then
  echo "SE_SESSION_QUEUE_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUE_PORT}" ]]; then
  echo "SE_SESSION_QUEUE_PORT not set, exiting!" 1>&2
  exit 1
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_DISTRIBUTOR_HOST" ]; then
  echo "Using SE_DISTRIBUTOR_HOST: ${SE_DISTRIBUTOR_HOST}"
  HOST_CONFIG="--host ${SE_DISTRIBUTOR_HOST}"
fi

if [ ! -z "$SE_DISTRIBUTOR_PORT" ]; then
  echo "Using SE_DISTRIBUTOR_PORT: ${SE_DISTRIBUTOR_PORT}"
  PORT_CONFIG="--port ${SE_DISTRIBUTOR_PORT}"
fi


java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar distributor \
  --sessions-host "${SE_SESSIONS_MAP_HOST}" --sessions-port "${SE_SESSIONS_MAP_PORT}" \
  --sessionqueue-host "${SE_SESSION_QUEUE_HOST}" --sessionqueue-port "${SE_SESSION_QUEUE_PORT}" \
  --publish-events tcp://"${SE_EVENT_BUS_HOST}":"${SE_EVENT_BUS_PUBLISH_PORT}" \
  --subscribe-events tcp://"${SE_EVENT_BUS_HOST}":"${SE_EVENT_BUS_SUBSCRIBE_PORT}" \
  --bind-host ${SE_BIND_HOST} \
  --bind-bus false \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SE_OPTS}
