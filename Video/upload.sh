#!/usr/bin/env bash

VIDEO_FOLDER=${VIDEO_FOLDER}
RCLONE_CONFIG=${RCLONE_CONFIG:-${SE_RCLONE_CONFIG}}
UPLOAD_COMMAND=${SE_UPLOAD_COMMAND:-"copy"}
UPLOAD_OPTS=${SE_UPLOAD_OPTS:-"-P --cutoff-mode SOFT --metadata --inplace"}
UPLOAD_RETAIN_LOCAL_FILE=${SE_UPLOAD_RETAIN_LOCAL_FILE:-"false"}
UPLOAD_PIPE_FILE_NAME=${SE_UPLOAD_PIPE_FILE_NAME:-"uploadpipe"}
VIDEO_INTERNAL_UPLOAD=${VIDEO_INTERNAL_UPLOAD:-$SE_VIDEO_INTERNAL_UPLOAD}
VIDEO_UPLOAD_BATCH_CHECK=${SE_VIDEO_UPLOAD_BATCH_CHECK:-"10"}
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}
process_name="video.uploader"

if [ "${VIDEO_INTERNAL_UPLOAD}" = "true" ]; then
  # If using RCLONE in the same container, write signal to /tmp internally
  UPLOAD_PIPE_FILE="/tmp/${UPLOAD_PIPE_FILE_NAME}"
  FORCE_EXIT_FILE="/tmp/force_exit"
else
  # If using external container for uploading, write signal to the video folder
  UPLOAD_PIPE_FILE="${VIDEO_FOLDER}/${UPLOAD_PIPE_FILE_NAME}"
  FORCE_EXIT_FILE="${VIDEO_FOLDER}/force_exit"
fi

if [ "${UPLOAD_RETAIN_LOCAL_FILE}" = "false" ]; then
  echo "$(date -u +"${ts_format}") [${process_name}] - UPLOAD_RETAIN_LOCAL_FILE is set to false, force to use RCLONE command: move"
  UPLOAD_COMMAND="move"
fi

function rename_rclone_env() {
  # This script is used to support passing environment variables for RCLONE configuration in Dynamic Grid
  # Dynamic Grid accepts environment variables with the prefix SE_*
  # RCLONE accepts environment variables with the prefix RCLONE_*
  # To pass the ENV vars to Dynamic Grid then to RCLONE, we need to rename the ENV vars from SE_RCLONE_* to RCLONE_*
  for var in $(env | cut -d= -f1); do
    if [[ "$var" == SE_RCLONE_* ]]; then
      suffix="${var#SE_RCLONE_}"
      new_var="RCLONE_$suffix"
      export "$new_var=${!var}"
    fi
  done
}

list_rclone_pid=()
function check_and_clear_background() {
  # Wait for a batch rclone processes to finish
  if [ ${#list_rclone_pid[@]} -eq ${VIDEO_UPLOAD_BATCH_CHECK} ]; then
    for pid in "${list_rclone_pid[@]}"; do
      wait ${pid}
    done
    list_rclone_pid=()
  fi

}

function rclone_upload() {
  local source=$1
  local target=$2
  echo "$(date -u +"${ts_format}") [${process_name}] - Uploading ${source} to ${target}"
  rclone --config ${RCLONE_CONFIG} ${UPLOAD_COMMAND} ${UPLOAD_OPTS} "${source}" "${target}" &
  list_rclone_pid+=($!)
  check_and_clear_background
}

function check_if_pid_alive() {
  local pid=$1
  if kill -0 "${pid}" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

function consume_pipe_file_in_background() {
  echo "$(date -u +"${ts_format}") [${process_name}] - Start consuming pipe file to upload"
  while read FILE DESTINATION <${UPLOAD_PIPE_FILE}; do
    if [ "${FILE}" = "exit" ]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - Received exit signal. Aborting upload process"
      return 0
    elif [ "$FILE" != "" ] && [ "$DESTINATION" != "" ]; then
      rclone_upload "${FILE}" "${DESTINATION}"
    fi
  done
  echo "$(date -u +"${ts_format}") [${process_name}] - Stopped consuming pipe file. Upload process is done"
  return 0
}

# Function to check if the named pipe exists
check_if_pipefile_exists() {
  if [ -p "${UPLOAD_PIPE_FILE}" ]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - Named pipe ${UPLOAD_PIPE_FILE} exists"
    return 0
  fi
  return 1
}

function wait_until_pipefile_exists() {
  echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for ${UPLOAD_PIPE_FILE} to be present"
  until check_if_pipefile_exists; do
    sleep 1
  done
}

function graceful_exit() {
  echo "$(date -u +"${ts_format}") [${process_name}] - Trapped SIGTERM/SIGINT/x so shutting down uploader"
  if ! check_if_pid_alive "${UPLOAD_PID}"; then
    consume_pipe_file_in_background &
    UPLOAD_PID=$!
  fi
  echo "exit" >>"${UPLOAD_PIPE_FILE}" &
  wait "${UPLOAD_PID}"
  echo "$(date -u +"${ts_format}") [${process_name}] - Uploader consumed all files in the pipe"
  rm -rf "${FORCE_EXIT_FILE}"
  echo "$(date -u +"${ts_format}") [${process_name}] - Uploader is ready to shutdown"
  exit 0
}

rename_rclone_env
trap graceful_exit SIGTERM SIGINT EXIT

while true; do
  wait_until_pipefile_exists
  if ! check_if_pid_alive "${UPLOAD_PID}"; then
    consume_pipe_file_in_background &
    UPLOAD_PID=$!
  fi
  while check_if_pid_alive "${UPLOAD_PID}"; do
    sleep 1
  done
done
