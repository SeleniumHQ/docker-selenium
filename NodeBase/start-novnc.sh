#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory NodeBase!

if [ "${START_XVFB}" = true ] ; then
  /opt/bin/noVNC/utils/launch.sh --listen 7900 --vnc localhost:5900
else
  echo "noVNC won't start because Xvfb is configured to not start."
fi
