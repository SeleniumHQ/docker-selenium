#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid EventBus..."

java -jar /opt/selenium/selenium-server.jar event-bus ${SE_OPTS}
