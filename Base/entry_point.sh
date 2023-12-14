#!/usr/bin/env bash
_log () {
    if [[ "$*" == "ERROR:"* ]] || [[ "$*" == "WARNING:"* ]] || [[ "${CONTAINER_LOGS_QUIET}" == "" ]]; then
        echo "$@"
    fi
}

# If the container started as the root user
if [ "$(id -u)" == 0 ]; then
    fix-permissions "${SE_DOWNLOAD_DIR}"
elif [ "$(id -u)" == "$(id -u ${SEL_USER})" ] && [ "$(id -g)" == "$(id -g ${SEL_USER})" ]; then
    # Trust SEL_USER is the desired non-root user to execute with sudo
    sudo -E fix-permissions "${SE_DOWNLOAD_DIR}"
else
    # For non-root user to change ownership
    # Relaxing permissions for OpenShift and other non-sudo environments
    # (https://docs.openshift.com/container-platform/latest/openshift_images/create-images.html#use-uid_create-images)
    if ! whoami &> /dev/null; then
        _log "There is no entry in /etc/passwd for our UID=$(id -u). Attempting to fix..."
        if [ -w /etc/passwd ]; then
            _log "Renaming user to ${USER_NAME:-default} ($(id -u):$(id -g)"
            # We cannot use "sed --in-place" since sed tries to create a temp file in
            # /etc/ and we may not have write access. Apply sed on our own temp file:
            sed --expression="s/^${SEL_USER}:/${USER_NAME:-default}:/" /etc/passwd > /tmp/passwd
            echo "${USER_NAME:-default}:x:$(id -u):$(id -g):${USER_NAME:-default} user:${HOME}:/bin/bash" >> /tmp/passwd
            cat /tmp/passwd > /etc/passwd
            rm /tmp/passwd
            _log "Added new ${USER_NAME:-default} user ($(id -u):$(id -g)). Fixed UID!"
        fi
    fi
    fix-permissions "${SE_DOWNLOAD_DIR}"
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
