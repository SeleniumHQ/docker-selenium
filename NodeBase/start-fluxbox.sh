#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory NodeDebug!

if [ "${START_XVFB}" = true ] ; then
  fluxbox -display ${DISPLAY}
else
  echo "Fluxbox won't start because Xvfb is configured to not start."
fi
