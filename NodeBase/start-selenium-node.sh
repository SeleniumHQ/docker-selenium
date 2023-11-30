#!/bin/bash

# Start the pulseaudio server
pulseaudio -D --exit-idle-time=-1

# Load the virtual sink and set it as default
pacmd load-module module-virtual-sink sink_name=v1
pacmd set-default-sink v1

# set the monitor of v1 sink to be the default source
pacmd set-default-source v1.monitor

rm -f /tmp/.X*lock

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

if [ "$GENERATE_CONFIG" = true ]; then
  echo "Generating Selenium Config"
  /opt/bin/generate_config
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

echo "Selenium Grid Node configuration: "
cat "$CONFIG_FILE"
echo "Starting Selenium Grid Node..."

CHROME_DRIVER_PATH_PROPERTY=-Dwebdriver.chrome.driver=/usr/bin/chromedriver
EDGE_DRIVER_PATH_PROPERTY=-Dwebdriver.edge.driver=/usr/bin/msedgedriver
GECKO_DRIVER_PATH_PROPERTY=-Dwebdriver.gecko.driver=/usr/bin/geckodriver

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  ${CHROME_DRIVER_PATH_PROPERTY} \
  ${EDGE_DRIVER_PATH_PROPERTY} \
  ${GECKO_DRIVER_PATH_PROPERTY} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} node \
  --bind-host ${SE_BIND_HOST} \
  --config "$CONFIG_FILE" \
  ${SE_OPTS}
