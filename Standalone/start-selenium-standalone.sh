#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory Standalone!

java ${JAVA_OPTS} -cp ${JAVA_CLASSPATH:-"/opt/selenium/*:."} org.openqa.grid.selenium.GridLauncherV3 \
    ${SE_OPTS}
