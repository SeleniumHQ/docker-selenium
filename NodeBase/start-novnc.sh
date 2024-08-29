#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory NodeBase!

if [ "${START_XVFB:-$SE_START_XVFB}" = true ]; then
  if [ "${START_VNC:-$SE_START_VNC}" = true ]; then
    if [ "${START_NO_VNC:-$SE_START_NO_VNC}" = true ]; then

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
