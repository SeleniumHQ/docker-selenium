#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

ROOT=/opt/selenium
CONF=${ROOT}/config.json

/opt/bin/generate_config >${CONF}

echo "Starting Vaadin Testbench Hub with configuration:"
cat ${CONF}

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Vaadin Testbench options: ${SE_OPTS}"
fi

java ${JAVA_OPTS} -jar /opt/selenium/vaadin-testbench-standalone.jar \
  -role hub \
  -hubConfig ${CONF} \
  ${SE_OPTS}
