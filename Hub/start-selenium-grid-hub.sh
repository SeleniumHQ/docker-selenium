#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

CONFIG_TOML_FILE=/opt/selenium/config.toml

/opt/bin/generate_config >${CONFIG_TOML_FILE}

echo "Starting Selenium Grid Hub with configuration: "
cat ${CONFIG_TOML_FILE}

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


java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar hub \
  --session-request-timeout ${SE_SESSION_REQUEST_TIMEOUT} \
  --session-retry-interval ${SE_SESSION_RETRY_INTERVAL} \
  --allow-cors ${SE_ALLOW_CORS} \
  --relax-checks ${SE_RELAX_CHECKS} \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SE_OPTS}
