#!/usr/bin/env bash

sudo -i -u user1 LD_LIBRARY_PATH=$LD_LIBRARY_PATH java -jar \
    /opt/selenium/selenium-server-standalone.jar -port $SELENIUM_PORT
