#!/usr/bin/env bash

NODE_CONFIG_DIRECTORY=${NODE_CONFIG_DIRECTORY:-"/opt/bin"}
#==============================================
# OpenShift or non-sudo environments support
# https://docs.openshift.com/container-platform/3.11/creating_images/guidelines.html#openshift-specific-guidelines
#==============================================

if ! whoami &>/dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >>/etc/passwd
  fi
fi

/usr/bin/supervisord --configuration /etc/supervisord.conf &

SUPERVISOR_PID=$!

function shutdown {
  echo "Trapped SIGTERM/SIGINT/x so shutting down supervisord..."
  if [ "${SE_NODE_GRACEFUL_SHUTDOWN}" = "true" ]; then
    echo "Waiting for Selenium Node to shutdown gracefully..."
    bash ${NODE_CONFIG_DIRECTORY}/nodePreStop.sh
  fi
  if [ -n "${SE_VIDEO_CONTAINER_NAME}" ]; then
    # For K8s, when video sidecar container and shareProcessNamespace are enabled in pod spec
    echo "Shutting down ${SE_VIDEO_CONTAINER_NAME} container..."
    pkill -f "${SE_VIDEO_CONTAINER_NAME}"
  fi
  kill -s SIGTERM ${SUPERVISOR_PID}
  wait ${SUPERVISOR_PID}
  echo "Shutdown complete"
}

trap shutdown SIGTERM SIGINT
wait ${SUPERVISOR_PID}
