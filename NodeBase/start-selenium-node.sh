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

if [ ! -z "$SE_DRIVER_OPTS" ]; then
  echo "Appending Selenium Driver Service property: ${SE_DRIVER_OPTS}"
fi

if [ "$GENERATE_CONFIG" = true ]; then
  echo "Generating Selenium Config"
  /opt/bin/generate_config
fi

EXTRA_LIBS=""

if [ ! -z "$SE_ENABLE_TRACING" ]; then
  EXTERNAL_JARS=$(</external_jars/.classpath.txt)
  EXTRA_LIBS="--ext "
  EXTRA_LIBS=${EXTRA_LIBS}:${EXTERNAL_JARS}
  echo "Tracing is enabled"
  echo "Classpath will be enriched with these external jars : " ${EXTRA_LIBS}
else
  echo "Tracing is disabled"
fi

echo "Selenium Grid Node configuration: "
cat "$CONFIG_FILE"
echo "Starting Selenium Grid Node..."

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  ${SE_DRIVER_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} node \
  --bind-host ${SE_BIND_HOST} \
  --config "$CONFIG_FILE" \
  ${SE_OPTS}
