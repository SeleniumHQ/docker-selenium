#!/usr/bin/env bash
#==============================================
# OpenShift or non-sudo environments support
# https://docs.openshift.com/container-platform/3.11/creating_images/guidelines.html#openshift-specific-guidelines
#==============================================

if ! whoami &>/dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >>/etc/passwd
  fi
fi

if [ -n "${VIRTUAL_ENV}" ]; then
  echo "Virtual environment detected at ${VIRTUAL_ENV}, activating..."
  source ${VIRTUAL_ENV}/bin/activate
  python3 --version
fi

#==============================================
# video-ready (video_ready.py) binds VIDEO_READY_PORT (default 9000) to serve
# readiness status. It only needs to run when recording can actually happen:
# either SE_RECORD_VIDEO is on, or SE_VIDEO_EVENT_DRIVEN lets a session turn
# it on dynamically via the se:recordVideo capability. In the remaining case
# (legacy mode, recording off) video_ready.py's own handler would always
# answer "ready" anyway, so skipping it avoids binding the port for nothing -
# recorder.conf reads this to gate video-ready's autostart/autorestart.
# Set it directly to override either default, e.g. force it off under
# network_mode: host regardless of the two vars above.
if [ -z "${SE_VIDEO_READY_ENABLED}" ]; then
  if [ "$(echo "${SE_RECORD_VIDEO:-true}" | tr '[:upper:]' '[:lower:]')" = "true" ] ||
    [ "$(echo "${SE_VIDEO_EVENT_DRIVEN:-false}" | tr '[:upper:]' '[:lower:]')" = "true" ]; then
    export SE_VIDEO_READY_ENABLED=true
  else
    export SE_VIDEO_READY_ENABLED=false
  fi
fi

supervisord --configuration /etc/supervisord.conf &

SUPERVISOR_PID=$!

function shutdown {
  echo "Trapped SIGTERM/SIGINT/x so shutting down supervisord..."
  kill -s SIGTERM ${SUPERVISOR_PID}
  wait ${SUPERVISOR_PID}
  echo "Shutdown complete"
}

trap shutdown SIGTERM SIGINT
wait ${SUPERVISOR_PID}
