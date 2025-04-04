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
