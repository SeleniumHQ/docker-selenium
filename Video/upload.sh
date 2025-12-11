#!/usr/bin/env bash

VIDEO_FOLDER=${VIDEO_FOLDER}
RCLONE_CONFIG=${RCLONE_CONFIG:-${SE_RCLONE_CONFIG}}
UPLOAD_COMMAND=${SE_UPLOAD_COMMAND:-"copy"}
UPLOAD_OPTS=${SE_UPLOAD_OPTS:-"-P --cutoff-mode SOFT --metadata --inplace"}
UPLOAD_RETAIN_LOCAL_FILE=${SE_UPLOAD_RETAIN_LOCAL_FILE:-"false"}
UPLOAD_PIPE_FILE_NAME=${SE_UPLOAD_PIPE_FILE_NAME:-"uploadpipe"}
VIDEO_INTERNAL_UPLOAD=${VIDEO_INTERNAL_UPLOAD:-$SE_VIDEO_INTERNAL_UPLOAD}
VIDEO_UPLOAD_BATCH_CHECK=${SE_VIDEO_UPLOAD_BATCH_CHECK:-"10"}
UPLOAD_RETRY_MAX_ATTEMPTS=${SE_UPLOAD_RETRY_MAX_ATTEMPTS:-3}
UPLOAD_RETRY_DELAY=${SE_UPLOAD_RETRY_DELAY:-5}
UPLOAD_FILE_READY_WAIT=${SE_UPLOAD_FILE_READY_WAIT:-3}
UPLOAD_FILE_STABILITY_RETRIES=${SE_UPLOAD_FILE_STABILITY_RETRIES:-5}
UPLOAD_VERIFY_CHECKSUM=${SE_UPLOAD_VERIFY_CHECKSUM:-"true"}
UPLOAD_VALIDATE_MP4=${SE_UPLOAD_VALIDATE_MP4:-"true"}
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
upload_success_count=0
upload_failed_count=0
graceful_exit_called=false

function validate_mp4_moov_atom() {
  local file=$1

  if [[ "${UPLOAD_VALIDATE_MP4}" != "true" ]]; then
    return 0
  fi

  # Only validate MP4/M4V files
  if [[ ! "${file}" =~ \.(mp4|m4v)$ ]]; then
    return 0
  fi

  # Check if file has moov atom using ffmpeg probe
  local error_output=$(ffmpeg -v error -i "${file}" -f null - 2>&1)

  if echo "${error_output}" | grep -q "moov atom not found"; then
    echo "$(date -u +"${ts_format}") [${process_name}] - ERROR: MP4 file missing moov atom: ${file}"
    return 1
  fi

  # Quick validation: check if ffmpeg can read the file
  if ! ffmpeg -v error -i "${file}" -t 0.1 -f null - 2>/dev/null; then
    echo "$(date -u +"${ts_format}") [${process_name}] - ERROR: MP4 file validation failed: ${file}"
    return 1
  fi

  echo "$(date -u +"${ts_format}") [${process_name}] - MP4 validation passed: ${file}"
  return 0
}

function verify_file_ready() {
  local file=$1

  # Check if file exists
  if [ ! -f "${file}" ]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - ERROR: File does not exist: ${file}"
    return 1
  fi

  # Check if file is readable
  if [ ! -r "${file}" ]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - ERROR: File is not readable: ${file}"
    return 1
  fi

  # Check if file has non-zero size
  local file_size=$(stat -f%z "${file}" 2>/dev/null || stat -c%s "${file}" 2>/dev/null)
  if [ -z "${file_size}" ] || [ "${file_size}" -eq 0 ]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - ERROR: File is empty: ${file}"
    return 1
  fi

  # Wait for file to be stable (no longer being written) with retries
  echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for file to stabilize: ${file}"
  local retry=0
  local stable=false

  while [ ${retry} -lt ${UPLOAD_FILE_STABILITY_RETRIES} ]; do
    local initial_size=${file_size}
    sleep ${UPLOAD_FILE_READY_WAIT}
    local final_size=$(stat -f%z "${file}" 2>/dev/null || stat -c%s "${file}" 2>/dev/null)

    if [ "${initial_size}" = "${final_size}" ]; then
      # Size is stable, force filesystem sync and verify again
      sync
      sleep 1
      local verify_size=$(stat -f%z "${file}" 2>/dev/null || stat -c%s "${file}" 2>/dev/null)

      if [ "${final_size}" = "${verify_size}" ]; then
        stable=true
        echo "$(date -u +"${ts_format}") [${process_name}] - File size stable at ${final_size} bytes after ${retry} retries"
        break
      fi
    fi

    retry=$((retry + 1))
    file_size=${final_size}

    if [ ${retry} -lt ${UPLOAD_FILE_STABILITY_RETRIES} ]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - File size changed (${initial_size} -> ${final_size}), waiting more (retry ${retry}/${UPLOAD_FILE_STABILITY_RETRIES})"
    fi
  done

  if [ "${stable}" != "true" ]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - WARNING: File did not stabilize after ${UPLOAD_FILE_STABILITY_RETRIES} retries: ${file}"
    return 1
  fi

  # Validate MP4 moov atom if enabled
  if ! validate_mp4_moov_atom "${file}"; then
    return 1
  fi

  echo "$(date -u +"${ts_format}") [${process_name}] - File verified ready for upload: ${file} (size: ${final_size} bytes)"
  return 0
}

function calculate_checksum() {
  local file=$1
  # Use md5sum for checksum (available on most systems)
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "${file}" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "${file}"
  else
    echo ""
  fi
}
function check_and_clear_background() {
  # Wait for a batch rclone processes to finish
  if [ ${#list_rclone_pid[@]} -eq ${VIDEO_UPLOAD_BATCH_CHECK} ]; then
    for pid in "${list_rclone_pid[@]}"; do
      wait ${pid}
    done
    list_rclone_pid=()
  fi

}

function rclone_upload_with_retry() {
  local source=$1
  local target=$2
  local attempt=1
  local source_checksum=""

  # Verify file is ready before attempting upload
  if ! verify_file_ready "${source}"; then
    echo "$(date -u +"${ts_format}") [${process_name}] - ERROR: File verification failed, skipping upload: ${source}"
    upload_failed_count=$((upload_failed_count + 1))
    return 1
  fi

  # Calculate checksum if verification is enabled
  if [ "${UPLOAD_VERIFY_CHECKSUM}" = "true" ]; then
    source_checksum=$(calculate_checksum "${source}")
    if [ -n "${source_checksum}" ]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - Source file checksum: ${source_checksum}"
    fi
  fi

  # Retry loop
  while [ ${attempt} -le ${UPLOAD_RETRY_MAX_ATTEMPTS} ]; do
    echo "$(date -u +"${ts_format}") [${process_name}] - Upload attempt ${attempt}/${UPLOAD_RETRY_MAX_ATTEMPTS}: ${source} to ${target}"

    # Execute rclone command
    if rclone --config ${RCLONE_CONFIG} ${UPLOAD_COMMAND} ${UPLOAD_OPTS} "${source}" "${target}"; then
      echo "$(date -u +"${ts_format}") [${process_name}] - SUCCESS: Upload completed: ${source} to ${target}"

      # Verify checksum if enabled and using copy command
      if [ "${UPLOAD_VERIFY_CHECKSUM}" = "true" ] && [ -n "${source_checksum}" ] && [ "${UPLOAD_COMMAND}" = "copy" ]; then
        # For copy command, verify source file still has same checksum
        local post_upload_checksum=$(calculate_checksum "${source}")
        if [ "${source_checksum}" = "${post_upload_checksum}" ]; then
          echo "$(date -u +"${ts_format}") [${process_name}] - Checksum verification passed: ${source_checksum}"
        else
          echo "$(date -u +"${ts_format}") [${process_name}] - WARNING: Checksum mismatch after upload (before: ${source_checksum}, after: ${post_upload_checksum})"
        fi
      fi

      # Update statistics file (for cross-process tracking)
      (
        flock -x 200
        local current_success=$(grep -oP 'upload_success_count=\K\d+' /tmp/upload_stats.txt 2>/dev/null || echo 0)
        echo "upload_success_count=$((current_success + 1))" >/tmp/upload_stats.txt.tmp
        local current_failed=$(grep -oP 'upload_failed_count=\K\d+' /tmp/upload_stats.txt 2>/dev/null || echo 0)
        echo "upload_failed_count=${current_failed}" >>/tmp/upload_stats.txt.tmp
        mv /tmp/upload_stats.txt.tmp /tmp/upload_stats.txt
      ) 200>/tmp/upload_stats.lock

      return 0
    else
      local exit_code=$?
      echo "$(date -u +"${ts_format}") [${process_name}] - FAILED: Upload attempt ${attempt} failed with exit code ${exit_code}: ${source}"

      if [ ${attempt} -lt ${UPLOAD_RETRY_MAX_ATTEMPTS} ]; then
        echo "$(date -u +"${ts_format}") [${process_name}] - Retrying in ${UPLOAD_RETRY_DELAY} seconds..."
        sleep ${UPLOAD_RETRY_DELAY}
      fi

      attempt=$((attempt + 1))
    fi
  done

  echo "$(date -u +"${ts_format}") [${process_name}] - ERROR: All upload attempts failed for: ${source}"

  # Update statistics file (for cross-process tracking)
  (
    flock -x 200
    local current_success=$(grep -oP 'upload_success_count=\K\d+' /tmp/upload_stats.txt 2>/dev/null || echo 0)
    echo "upload_success_count=${current_success}" >/tmp/upload_stats.txt.tmp
    local current_failed=$(grep -oP 'upload_failed_count=\K\d+' /tmp/upload_stats.txt 2>/dev/null || echo 0)
    echo "upload_failed_count=$((current_failed + 1))" >>/tmp/upload_stats.txt.tmp
    mv /tmp/upload_stats.txt.tmp /tmp/upload_stats.txt
  ) 200>/tmp/upload_stats.lock

  return 1
}

function rclone_upload() {
  local source=$1
  local target=$2
  rclone_upload_with_retry "${source}" "${target}" &
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

function wait_for_active_uploads() {
  if [ ${#list_rclone_pid[@]} -gt 0 ]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for ${#list_rclone_pid[@]} active upload process(es) to complete"
    for pid in "${list_rclone_pid[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for upload process (PID: $pid)"
        wait "$pid" 2>/dev/null || true
      fi
    done
    echo "$(date -u +"${ts_format}") [${process_name}] - All active upload processes completed"
    list_rclone_pid=()
  fi
}

function graceful_exit() {
  # Prevent duplicate execution (trap catches both SIGTERM and EXIT)
  if [ "$graceful_exit_called" = "true" ]; then
    return 0
  fi
  graceful_exit_called=true

  echo "$(date -u +"${ts_format}") [${process_name}] - Trapped SIGTERM/SIGINT/x so shutting down uploader"

  # Signal the pipe consumer to stop accepting new files
  if ! check_if_pid_alive "${UPLOAD_PID}"; then
    consume_pipe_file_in_background &
    UPLOAD_PID=$!
  fi
  echo "exit" >>"${UPLOAD_PIPE_FILE}" &
  wait "${UPLOAD_PID}"
  echo "$(date -u +"${ts_format}") [${process_name}] - Uploader consumed all files in the pipe"

  # Wait for all active background rclone uploads to complete
  wait_for_active_uploads

  # Log upload statistics from file (written by background processes)
  if [ -f "/tmp/upload_stats.txt" ]; then
    source "/tmp/upload_stats.txt" 2>/dev/null || true
  fi
  local total_uploads=$((upload_success_count + upload_failed_count))
  echo "$(date -u +"${ts_format}") [${process_name}] - Upload Statistics:"
  echo "$(date -u +"${ts_format}") [${process_name}] -   Total uploads attempted: ${total_uploads}"
  echo "$(date -u +"${ts_format}") [${process_name}] -   Successful uploads: ${upload_success_count}"
  echo "$(date -u +"${ts_format}") [${process_name}] -   Failed uploads: ${upload_failed_count}"

  rm -rf "${FORCE_EXIT_FILE}"
  rm -rf "/tmp/upload_stats.txt"
  echo "$(date -u +"${ts_format}") [${process_name}] - Uploader is ready to shutdown"
  exit 0
}

rename_rclone_env
trap graceful_exit SIGTERM SIGINT EXIT

while true; do
  # Exit main loop if graceful shutdown is in progress
  if [ "$graceful_exit_called" = "true" ]; then
    break
  fi

  wait_until_pipefile_exists

  # Exit main loop if graceful shutdown is in progress
  if [ "$graceful_exit_called" = "true" ]; then
    break
  fi

  if ! check_if_pid_alive "${UPLOAD_PID}"; then
    consume_pipe_file_in_background &
    UPLOAD_PID=$!
  fi

  while check_if_pid_alive "${UPLOAD_PID}"; do
    # Exit main loop if graceful shutdown is in progress
    if [ "$graceful_exit_called" = "true" ]; then
      break 2 # Break out of both while loops
    fi
    sleep 1
  done
done
