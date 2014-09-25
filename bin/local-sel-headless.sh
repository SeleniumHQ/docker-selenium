#!/usr/bin/env bash

sudo -E -i -u user1 \
    DOCKER_HOST_IP=$DOCKER_HOST_IP \
    java -jar /opt/selenium/selenium-server-standalone.jar -port $SELENIUM_PORT
