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

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar hub \
  --config ${CONFIG_TOML_FILE} \
  ${SE_OPTS}
