#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Hub..."

java -jar /opt/selenium/selenium-server.jar hub
