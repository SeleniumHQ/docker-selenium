#!/usr/bin/env bash

if [ "${START_XVFB}" = true ] ; then
  export GEOMETRY="${SCREEN_WIDTH}""x""${SCREEN_HEIGHT}""x""${SCREEN_DEPTH}"

  rm -f /tmp/.X*lock

  /usr/bin/Xvfb ${DISPLAY} -screen 0 ${GEOMETRY} -ac +extension RANDR
else
  echo "Xvfb won't start. Chrome/Firefox can only run in headless mode. Remember to set the 'headless' flag in your test."
fi
