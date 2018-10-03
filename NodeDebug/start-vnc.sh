#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory NodeDebug!

if [ "${START_XVFB}" = true ] ; then
  if [ ! -z $VNC_NO_PASSWORD ]; then
      echo "Starting VNC server without password authentication"
      X11VNC_OPTS=
  else
      X11VNC_OPTS=-usepw
  fi

  for i in $(seq 1 10)
  do
    sleep 1
    xdpyinfo -display ${DISPLAY} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      break
    fi
    echo "Waiting for Xvfb..."
  done

  x11vnc ${X11VNC_OPTS} -forever -shared -rfbport 5900 -display ${DISPLAY}
else
  echo "Vnc won't start because Xvfb is configured to not start."
fi
