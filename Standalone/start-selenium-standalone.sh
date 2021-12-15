#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory Standalone!

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

/opt/bin/generate_config

echo "Selenium Grid Standalone configuration: "
cat /opt/selenium/config.toml
echo "Starting Selenium Grid Standalone..."
java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar standalone \
  --bind-host ${SE_BIND_HOST} \
  --config /opt/selenium/config.toml \
  ${SE_OPTS}