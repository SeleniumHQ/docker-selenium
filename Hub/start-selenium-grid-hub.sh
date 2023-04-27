#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_HUB_HOST" ]; then
  echo "Using SE_HUB_HOST: ${SE_HUB_HOST}"
  HOST_CONFIG="--host ${SE_HUB_HOST}"
fi

if [ ! -z "$SE_HUB_PORT" ]; then
  echo "Using SE_HUB_PORT: ${SE_HUB_PORT}"
  PORT_CONFIG="--port ${SE_HUB_PORT}"
fi

if [ ! -z "$SE_SUB_PATH" ]; then
  echo "Using SE_SUB_PATH: ${SE_SUB_PATH}"
  SUB_PATH_CONFIG="--sub-path ${SE_SUB_PATH}"
fi

EXTRA_LIBS="/opt/selenium/selenium-http-jdk-client.jar"

if [ ! -z "$SE_ENABLE_TRACING" ]; then
  EXTERNAL_JARS=$(</external_jars/.classpath.txt)
  EXTRA_LIBS=${EXTRA_LIBS}:${EXTERNAL_JARS}
  echo "Tracing is enabled"
  echo "Classpath will be enriched with these external jars : " ${EXTRA_LIBS}
else
  echo "Tracing is disabled"
fi


java ${JAVA_OPTS:-$SE_JAVA_OPTS} -Dwebdriver.http.factory=jdk-http-client \
  -jar /opt/selenium/selenium-server.jar \
  --ext ${EXTRA_LIBS} hub \
  --session-request-timeout ${SE_SESSION_REQUEST_TIMEOUT} \
  --session-retry-interval ${SE_SESSION_RETRY_INTERVAL} \
  --relax-checks ${SE_RELAX_CHECKS} \
  --bind-host ${SE_BIND_HOST} \
  --config /opt/selenium/config.toml \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SUB_PATH_CONFIG} \
  ${SE_OPTS}
