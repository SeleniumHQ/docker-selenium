#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory Standalone!

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar standalone \
  --relax-checks ${SE_RELAX_CHECKS} \
  --session-timeout ${SE_NODE_SESSION_TIMEOUT} \
  --max-sessions ${SE_NODE_MAX_SESSIONS} \
  --override-max-sessions ${SE_NODE_OVERRIDE_MAX_SESSIONS} \
  ${SE_OPTS}