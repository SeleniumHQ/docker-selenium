#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory NodeBase!

if [ "${START_XVFB:-$SE_START_XVFB}" = true ]; then
  if [ "${START_VNC:-$SE_START_VNC}" = true ]; then
    # Centering wallpaper
    for i in $(seq 1 10); do
      sleep 0.5
      echo "Centering wallpaper"
      /usr/bin/fbsetbg -u Esetroot -c /usr/share/images/fluxbox/ubuntu-light.png
      if [ $? -eq 0 ]; then
        break
      fi
    done
    VNC_NO_PASSWORD=${VNC_NO_PASSWORD:-$SE_VNC_NO_PASSWORD}
    if [ "${VNC_NO_PASSWORD}" = "true" ] || [ "${VNC_NO_PASSWORD}" = "1" ]; then
      echo "Starting VNC server without password authentication"
      X11VNC_OPTS=
    else
      X11VNC_OPTS=-usepw
    fi

    VNC_VIEW_ONLY=${VNC_VIEW_ONLY:-$SE_VNC_VIEW_ONLY}
    if [ "${VNC_VIEW_ONLY}" = "true" ] || [ "${VNC_VIEW_ONLY}" = "1" ]; then
      echo "Starting VNC server with viewonly option"
      X11VNC_OPTS="${X11VNC_OPTS} -viewonly"
    fi

    VNC_PASSWORD=${VNC_PASSWORD:-$SE_VNC_PASSWORD}
    if [ ! -z $VNC_PASSWORD ]; then
      echo "Starting VNC server with custom password"
      x11vnc -storepasswd ${VNC_PASSWORD} ${HOME}/.vnc/passwd
    fi

    for i in $(seq 1 10); do
      sleep 1
      xdpyinfo -display ${DISPLAY} >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        break
      fi
      echo "Waiting for Xvfb..."
    done

    # Guard against unreasonably high nofile limits. See https://github.com/SeleniumHQ/docker-selenium/issues/2045
    # Try to set a new limit if the current limit is too high, or the user explicitly specified a custom limit
    TOO_HIGH_ULIMIT=100000
    if [[ $(ulimit -n) -gt $TOO_HIGH_ULIMIT || ! -z "${SE_VNC_ULIMIT}" ]]; then
      NEW_ULIMIT=${SE_VNC_ULIMIT:-${TOO_HIGH_ULIMIT}}
      echo "Trying to update the open file descriptor limit from $(ulimit -n) to ${NEW_ULIMIT}."
      ulimit -n ${NEW_ULIMIT}
      if [ $? -eq 0 ]; then
        echo "Successfully updated the open file descriptor limit."
      else
        echo "The open file descriptor limit could not be updated."
      fi
    fi

    x11vnc ${X11VNC_OPTS} -forever -shared -rfbport ${VNC_PORT:-$SE_VNC_PORT} -rfbportv6 ${VNC_PORT:-$SE_VNC_PORT} -display ${DISPLAY}
  else
    echo "VNC won't start because SE_START_VNC is false."
  fi
else
  echo "VNC won't start because Xvfb is configured to not start."
fi
