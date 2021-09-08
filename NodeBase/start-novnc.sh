#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory NodeBase!

if [ "${START_XVFB}" = true ] ; then
  if [ "${START_NO_VNC}" = true ] ; then
    /opt/bin/noVNC/utils/launch.sh --listen ${NO_VNC_PORT:-7900} --vnc localhost:${VNC_PORT:-5900}
  else
    echo "noVNC won't start because START_NO_VNC is false."
  fi
else
  echo "noVNC won't start because Xvfb is configured to not start."
fi
