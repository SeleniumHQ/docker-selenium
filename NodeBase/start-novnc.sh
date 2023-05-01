#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory NodeBase!

if [ "${START_XVFB:-$SE_START_XVFB}" = true ] ; then
  if [ "${START_VNC:-$SE_START_VNC}" = true ] ; then
    if [ "${START_NO_VNC:-$SE_START_NO_VNC}" = true ] ; then
      /opt/bin/noVNC/utils/novnc_proxy --listen ${NO_VNC_PORT:-$SE_NO_VNC_PORT} --vnc localhost:${VNC_PORT:-$SE_VNC_PORT}
    else
      echo "noVNC won't start because SE_START_NO_VNC is false."
    fi
  else
    echo "noVNC won't start because VNC is configured to not start."
  fi
else
  echo "noVNC won't start because Xvfb is configured to not start."
fi
