#!/usr/bin/env bash

VIDEO_FOLDER=${VIDEO_FOLDER}
UPLOAD_CONFIG_DIRECTORY=${SE_UPLOAD_CONFIG_DIRECTORY:-"/opt/bin"}
UPLOAD_CONFIG_FILE_NAME=${SE_UPLOAD_CONFIG_FILE_NAME:-"upload.conf"}
UPLOAD_COMMAND=${SE_UPLOAD_COMMAND:-"copy"}
UPLOAD_OPTS=${SE_UPLOAD_OPTS:-"-P --cutoff-mode SOFT --metadata"}
UPLOAD_RETAIN_LOCAL_FILE=${SE_UPLOAD_RETAIN_LOCAL_FILE:-"false"}
UPLOAD_PIPE_FILE_NAME=${SE_UPLOAD_PIPE_FILE_NAME:-"uploadpipe"}
SE_VIDEO_INTERNAL_UPLOAD=${SE_VIDEO_INTERNAL_UPLOAD:-"false"}
VIDEO_UPLOAD_ENABLED=${SE_VIDEO_UPLOAD_ENABLED:-"false"}
VIDEO_UPLOAD_BATCH_CHECK=${SE_VIDEO_UPLOAD_BATCH_CHECK:-"10"}
process_name="video.uploader"

if [ "${SE_VIDEO_INTERNAL_UPLOAD}" = "true" ];
then
    # If using RCLONE in the same container, write signal to /tmp internally
    UPLOAD_PIPE_FILE="/tmp/${UPLOAD_PIPE_FILE_NAME}"
    FORCE_EXIT_FILE="/tmp/force_exit"
else
    # If using external container for uploading, write signal to the video folder
    UPLOAD_PIPE_FILE="${VIDEO_FOLDER}/${UPLOAD_PIPE_FILE_NAME}"
    FORCE_EXIT_FILE="${VIDEO_FOLDER}/force_exit"
fi

if [ "${UPLOAD_RETAIN_LOCAL_FILE}" = "false" ];
then
  echo "$(date +%FT%T%Z) [${process_name}] - UPLOAD_RETAIN_LOCAL_FILE is set to false, force to use RCLONE command: move"
  UPLOAD_COMMAND="move"
fi

function rename_rclone_env() {
  # This script is used to support passing environment variables for RCLONE configuration in Dynamic Grid
  # Dynamic Grid accepts environment variables with the prefix SE_*
  # RCLONE accepts environment variables with the prefix RCLONE_*
  # To pass the ENV vars to Dynamic Grid then to RCLONE, we need to rename the ENV vars from SE_RCLONE_* to RCLONE_*
  for var in $(env | cut -d= -f1); do
      if [[ "$var" == SE_RCLONE_* ]];
      then
          suffix="${var#SE_RCLONE_}"
          new_var="RCLONE_$suffix"
          export "$new_var=${!var}"
      fi
  done
}

function consume_pipe_file() {
    while read FILE DESTINATION < ${UPLOAD_PIPE_FILE};
    do
        if [ "${FILE}" = "exit" ];
        then
            FORCE_EXIT=true
            exit
        elif [ "$FILE" != "" ] && [ "$DESTINATION" != "" ];
        then
            rclone_upload "${FILE}" "${DESTINATION}"
        elif [ -f ${FORCE_EXIT_FILE} ];
        then
            echo "$(date +%FT%T%Z) [${process_name}] - Force exit signal detected"
            exit
        fi
    done
}

list_rclone_pid=()
function check_and_clear_background() {
    # Wait for a batch rclone processes to finish
    if [ ${#list_rclone_pid[@]} -eq ${VIDEO_UPLOAD_BATCH_CHECK} ]; then
        for pid in "${list_rclone_pid[@]}";
        do
            wait ${pid}
        done
        list_rclone_pid=()
    fi

}

function rclone_upload() {
    local source=$1
    local target=$2
    echo "$(date +%FT%T%Z) [${process_name}] - Uploading ${source} to ${target}"
    exec rclone --config ${UPLOAD_CONFIG_DIRECTORY}/${UPLOAD_CONFIG_FILE_NAME} ${UPLOAD_COMMAND} ${UPLOAD_OPTS} "${source}" "${target}" &
}

function graceful_exit() {
    echo "$(date +%FT%T%Z) [${process_name}] - Uploader is shutting down"
    if [ "${FORCE_EXIT}" != "true" ]; then
        consume_pipe_file
    fi
    echo "$(date +%FT%T%Z) [${process_name}] - Uploader consumed all files in the pipe"
    rm -rf ${FORCE_EXIT_FILE}
    echo "$(date +%FT%T%Z) [${process_name}] - Uploader is ready to shutdown"
}
trap graceful_exit SIGTERM SIGINT EXIT

# Function to create the named pipe if it doesn't exist
function create_named_pipe() {
    if [ ! -p "${UPLOAD_PIPE_FILE}" ];
    then
        if [ -e "${UPLOAD_PIPE_FILE}" ];
        then
            rm -f "${UPLOAD_PIPE_FILE}"
        fi
        mkfifo "${UPLOAD_PIPE_FILE}"
        echo "$(date +%FT%T%Z) [${process_name}] - Created named pipe ${UPLOAD_PIPE_FILE}"
    fi
}

TIMEOUT=300 # Timeout in seconds (5 minutes)
START_TIME=$(date +%s)

while true; do
    if [ -e "${UPLOAD_PIPE_FILE}" ];
    then
        if [ -p "${UPLOAD_PIPE_FILE}" ];
        then
            break
        else
            echo "$(date +%FT%T%Z) [${process_name}] - ${UPLOAD_PIPE_FILE} exists but is not a named pipe"
            create_named_pipe
        fi
    else
        create_named_pipe
    fi

    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    if [ ${ELAPSED_TIME} -ge ${TIMEOUT} ];
    then
        echo "$(date +%FT%T%Z) [${process_name}] - Timeout waiting for ${UPLOAD_PIPE_FILE} to be created"
        exit 1
    fi

    echo "$(date +%FT%T%Z) [${process_name}] - Waiting for ${UPLOAD_PIPE_FILE} to be created"
    sleep 1
done

echo "$(date +%FT%T%Z) [${process_name}] - Waiting for video files put into pipe for proceeding to upload"

rename_rclone_env
consume_pipe_file
