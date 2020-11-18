#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Router..."

if [[ -z "${SE_SESSIONS_MAP_HOST}" ]]; then
  echo "SE_SESSIONS_MAP_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSIONS_MAP_PORT}" ]]; then
  echo "SE_SESSIONS_MAP_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_DISTRIBUTOR_HOST}" ]]; then
  echo "DISTRIBUTOR_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_DISTRIBUTOR_PORT}" ]]; then
  echo "DISTRIBUTOR_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUER_HOST}" ]]; then
  echo "SE_SESSION_QUEUER_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUER_PORT}" ]]; then
  echo "SE_SESSION_QUEUER_PORT not set, exiting!" 1>&2
  exit 1
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server.jar router \
  --sessions-host "${SE_SESSIONS_MAP_HOST}" --sessions-port "${SE_SESSIONS_MAP_PORT}" \
  --distributor-host "${SE_DISTRIBUTOR_HOST}" --distributor-port "${SE_DISTRIBUTOR_PORT}" \
  --sessionqueuer-host "${SE_SESSION_QUEUER_HOST}" --sessionqueuer-port "${SE_SESSION_QUEUER_PORT}" \
  --relax-checks true ${SE_OPTS}
