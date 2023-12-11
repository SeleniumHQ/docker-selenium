#!/usr/bin/env bash
_log () {
    if [[ "$*" == "ERROR:"* ]] || [[ "$*" == "WARNING:"* ]] || [[ "${CONTAINER_LOGS_QUIET}" == "" ]]; then
        echo "$@"
    fi
}

#==============================================
# OpenShift or non-sudo environments support
# https://docs.openshift.com/container-platform/3.11/creating_images/guidelines.html#openshift-specific-guidelines
#==============================================

if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-${SEL_USER}}:x:$(id -u):0:${USER_NAME:-${SEL_USER}} user:${HOME}:${SE_DOWNLOAD_DIR}:/var:/opt:/sbin/nologin" >> /etc/passwd
  fi
fi

MKDIR_EXTRA=${SE_DOWNLOAD_DIR}","${MKDIR_EXTRA}
CHOWN_EXTRA=${MKDIR_EXTRA}","${CHOWN_EXTRA}

if [ -n "${MKDIR_EXTRA}" ]; then
    for extra_dir in $(echo "${MKDIR_EXTRA}" | tr ',' ' '); do
        _log "Creating directory ${extra_dir} ${MKDIR_EXTRA_OPTS:+(mkdir options: ${MKDIR_EXTRA_OPTS})}"
        # shellcheck disable=SC2086
        sudo mkdir ${MKDIR_EXTRA_OPTS:-"-p"} "${extra_dir}"
    done
fi

if [ -n "${CHOWN_EXTRA}" ]; then
    for extra_dir in $(echo "${CHOWN_EXTRA}" | tr ',' ' '); do
        _log "Changing ${extra_dir} ownership. ${extra_dir} is owned by ${SEL_USER} ${CHOWN_EXTRA_OPTS:+(chown options: ${CHOWN_EXTRA_OPTS})}"
        # shellcheck disable=SC2086
        sudo chown ${CHOWN_EXTRA_OPTS:-"-R"} "${SEL_UID}:${SEL_GID}" "${extra_dir}"
        sudo -E fix-permissions "${extra_dir}"
    done
fi

# Raise error if the user isn't able to write files to download dir
if [ -n "${CHOWN_EXTRA}" ]; then
    for extra_dir in $(echo "${CHOWN_EXTRA}" | tr ',' ' '); do
        if [[ ! -w ${extra_dir} ]]; then
            _log "ERROR: no write access to download dir ${SE_DOWNLOAD_DIR}. Please correct the permissions and restart."
        fi
    done
fi

/usr/bin/supervisord --configuration /etc/supervisord.conf &

SUPERVISOR_PID=$!

function shutdown {
    echo "Trapped SIGTERM/SIGINT/x so shutting down supervisord..."
    kill -s SIGTERM ${SUPERVISOR_PID}
    wait ${SUPERVISOR_PID}
    echo "Shutdown complete"
}

trap shutdown SIGTERM SIGINT
wait ${SUPERVISOR_PID}
