#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid EventBus..."

if [ ! -z "$SE_EVENT_BUS_HOST" ]; then
  echo "Using SE_EVENT_BUS_HOST: ${SE_EVENT_BUS_HOST}"
  HOST_CONFIG="--host ${SE_EVENT_BUS_HOST}"
fi

if [ ! -z "$SE_EVENT_BUS_PORT" ]; then
  echo "Using SE_EVENT_BUS_PORT: ${SE_EVENT_BUS_PORT}"
  PORT_CONFIG="--port ${SE_EVENT_BUS_PORT}"
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_LOG_LEVEL" ]; then
  echo "Appending Selenium options: --log-level ${SE_LOG_LEVEL}"
  SE_OPTS="$SE_OPTS --log-level ${SE_LOG_LEVEL}"
fi

EXTRA_LIBS=""

if [ ! -z "$SE_ENABLE_TRACING" ]; then
  EXTERNAL_JARS=$(</external_jars/.classpath.txt)
  [ -n "$EXTRA_LIBS" ] && [ -n "${EXTERNAL_JARS}" ] && EXTRA_LIBS=${EXTRA_LIBS}:
  EXTRA_LIBS="--ext "${EXTRA_LIBS}${EXTERNAL_JARS}
  echo "Tracing is enabled"
  echo "Classpath will be enriched with these external jars : " ${EXTRA_LIBS}
else
  echo "Tracing is disabled"
fi

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} event-bus \
  --bind-host ${SE_BIND_HOST} \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SE_OPTS}
