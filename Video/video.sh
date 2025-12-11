#!/usr/bin/env bash

VIDEO_SIZE="${SE_SCREEN_WIDTH}""x""${SE_SCREEN_HEIGHT}"
DISPLAY_CONTAINER_NAME=${DISPLAY_CONTAINER_NAME}
DISPLAY_NUM=${DISPLAY_NUM}
VIDEO_FILE_NAME=${FILE_NAME:-$SE_VIDEO_FILE_NAME}
FRAME_RATE=${FRAME_RATE:-$SE_FRAME_RATE}
CODEC=${CODEC:-$SE_CODEC}
PRESET=${PRESET:-$SE_PRESET}
VIDEO_FOLDER=${VIDEO_FOLDER}
VIDEO_UPLOAD_ENABLED=${VIDEO_UPLOAD_ENABLED:-$SE_VIDEO_UPLOAD_ENABLED}
VIDEO_INTERNAL_UPLOAD=${VIDEO_INTERNAL_UPLOAD:-$SE_VIDEO_INTERNAL_UPLOAD}
VIDEO_CONFIG_DIRECTORY=${VIDEO_CONFIG_DIRECTORY:-"/opt/bin"}
UPLOAD_DESTINATION_PREFIX=${UPLOAD_DESTINATION_PREFIX:-$SE_UPLOAD_DESTINATION_PREFIX}
UPLOAD_PIPE_FILE_NAME=${SE_UPLOAD_PIPE_FILE_NAME:-"uploadpipe"}
SE_SERVER_PROTOCOL=${SE_SERVER_PROTOCOL:-"http"}
poll_interval=${SE_VIDEO_POLL_INTERVAL:-2}
max_attempts=${SE_VIDEO_WAIT_ATTEMPTS:-50}
file_ready_max_attempts=${SE_VIDEO_FILE_READY_WAIT_ATTEMPTS:-5}
wait_uploader_shutdown_max_attempts=${SE_VIDEO_WAIT_UPLOADER_SHUTDOWN_ATTEMPTS:-5}
graceful_stop_delay=${SE_VIDEO_GRACEFUL_STOP_DELAY:-5}
min_recording_duration=${SE_VIDEO_MIN_RECORDING_DURATION:-5}
video_validation_enabled=${SE_VIDEO_VALIDATION_ENABLED:-"true"}
video_fix_corrupted=${SE_VIDEO_FIX_CORRUPTED:-"true"}
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}
process_name="video.recorder"

if [ "${SE_VIDEO_RECORD_STANDALONE}" = "true" ]; then
  JQ_SESSION_ID_QUERY=".value.nodes[0]?.slots[-1]?.session?.sessionId"
  JQ_SESSION_CAPABILITIES_QUERY=".value.nodes[0]?.slots[-1]?.session?.capabilities"
  SE_NODE_PORT=${SE_NODE_PORT:-"4444"}
  NODE_STATUS_ENDPOINT="${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT}/status"
else
  JQ_SESSION_ID_QUERY=".value.node?.slots[-1]?.session?.sessionId"
  JQ_SESSION_CAPABILITIES_QUERY=".value.node?.slots[-1]?.session?.capabilities"
  SE_NODE_PORT=${SE_NODE_PORT:-"5555"}
  NODE_STATUS_ENDPOINT="${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT}/status"
fi

BASIC_AUTH="Authorization: Basic YWRtaW46YWRtaW4="
if [ -n "${SE_ROUTER_USERNAME}" ] && [ -n "${SE_ROUTER_PASSWORD}" ]; then
  BASIC_AUTH="$(echo -en "${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}" | base64 -w0)"
  BASIC_AUTH="Authorization: Basic ${BASIC_AUTH}"
fi

# Set headers if Node Registration Secret is set
if [ ! -z "${SE_REGISTRATION_SECRET}" ]; then
  HEADERS="X-REGISTRATION-SECRET: ${SE_REGISTRATION_SECRET}"
else
  HEADERS="X-REGISTRATION-SECRET;"
fi

if [ -d "${VIDEO_FOLDER}" ]; then
  echo "$(date -u +"${ts_format}") [${process_name}] - Video folder exists: ${VIDEO_FOLDER}"
else
  echo "$(date -u +"${ts_format}") [${process_name}] - Video folder does not exist: ${VIDEO_FOLDER}. Due to permission, folder name could not be changed via environment variable. Exiting..."
  exit 1
fi

if [ "${VIDEO_INTERNAL_UPLOAD}" = "true" ]; then
  # If using RCLONE in the same container, write signal to /tmp internally
  UPLOAD_PIPE_FILE="/tmp/${UPLOAD_PIPE_FILE_NAME}"
  FORCE_EXIT_FILE="/tmp/force_exit"
else
  # If using external container for uploading, write signal to the video folder
  UPLOAD_PIPE_FILE="${VIDEO_FOLDER}/${UPLOAD_PIPE_FILE_NAME}"
  FORCE_EXIT_FILE="${VIDEO_FOLDER}/force_exit"
fi

# Function to create the named pipe if it doesn't exist
function create_named_pipe() {
  if [ "${VIDEO_UPLOAD_ENABLED}" = "true" ]; then
    if [ ! -p "${UPLOAD_PIPE_FILE}" ]; then
      if [ -e "${UPLOAD_PIPE_FILE}" ]; then
        rm -f "${UPLOAD_PIPE_FILE}"
      fi
      mkfifo "${UPLOAD_PIPE_FILE}"
      echo "$(date -u +"${ts_format}") [${process_name}] - Created named pipe ${UPLOAD_PIPE_FILE}"
    fi
  fi
}

function wait_for_display() {
  DISPLAY=${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM}.0
  export DISPLAY=${DISPLAY}
  echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for the display ${DISPLAY} is open"
  until xset b off >/dev/null 2>&1; do
    sleep ${poll_interval}
  done
  if [ -z "$SE_SCREEN_WIDTH" -o -z "$SE_SCREEN_HEIGHT" ]; then
    VIDEO_SIZE=$(xdpyinfo | grep 'dimensions:' | awk '{print $2}')
  fi
  echo "$(date -u +"${ts_format}") [${process_name}] - Display ${DISPLAY} is open with dimensions ${VIDEO_SIZE}"
}

function check_if_api_respond() {
  endpoint_checks=$(curl --noproxy "*" -H "${BASIC_AUTH}" -sk -o /dev/null -w "%{http_code}" "${NODE_STATUS_ENDPOINT}")
  if [[ "${endpoint_checks}" != "200" ]]; then
    python3 /opt/bin/validate_endpoint.py "${NODE_STATUS_ENDPOINT}"
    return 1
  fi
  return 0
}

function wait_for_api_respond() {
  echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for Node endpoint responds"
  until check_if_api_respond; do
    sleep ${poll_interval}
  done
  echo "$(date -u +"${ts_format}") [${process_name}] - Node endpoint is responding now. Proceeding next steps..."
  return 0
}

function wait_util_uploader_shutdown() {
  wait=0
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]] && [[ "${VIDEO_INTERNAL_UPLOAD}" != "true" ]]; then
    while [[ -f ${FORCE_EXIT_FILE} ]] && [[ ${wait} -lt ${wait_uploader_shutdown_max_attempts} ]]; do
      echo "exit" >>${UPLOAD_PIPE_FILE} &
      echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for force exit file to be consumed by external upload container"
      sleep ${poll_interval}
      wait=$((wait + 1))
    done
  fi
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]] && [[ "${VIDEO_INTERNAL_UPLOAD}" = "true" ]]; then
    while [[ $(pgrep rclone | wc -l) -gt 0 ]]; do
      echo "exit" >>${UPLOAD_PIPE_FILE} &
      echo "$(date -u +"${ts_format}") [${process_name}] - Recorder is waiting for RCLONE to finish"
      sleep ${poll_interval}
    done
  fi
}

function wait_for_pipe_to_drain() {
  if [[ "${VIDEO_UPLOAD_ENABLED}" != "true" ]] || [[ -z "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    return 0
  fi

  local wait_count=0
  local max_drain_wait=${SE_VIDEO_WAIT_PIPE_DRAIN:-10}

  echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for upload pipe to drain before shutdown"

  # Give uploader time to process queued files
  while [[ ${wait_count} -lt ${max_drain_wait} ]]; do
    local upload_active=false

    # Check for active rclone/upload processes
    if [[ "${VIDEO_INTERNAL_UPLOAD}" = "true" ]]; then
      # For internal upload, check rclone processes
      local rclone_count=$(pgrep rclone 2>/dev/null | wc -l)
      if [[ ${rclone_count} -gt 0 ]]; then
        upload_active=true
        echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for ${rclone_count} active rclone upload(s) to complete (${wait_count}/${max_drain_wait})"
      fi
    else
      # For external upload, just give some time for pipe to be consumed
      # We can't check external container processes, so use a fixed wait
      if [[ ${wait_count} -lt 3 ]]; then
        upload_active=true
        echo "$(date -u +"${ts_format}") [${process_name}] - Giving external uploader time to process queue (${wait_count}/3)"
      fi
    fi

    if [[ "${upload_active}" = "false" ]]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - Upload pipe drained, no active uploads"
      break
    fi

    sleep ${poll_interval}
    wait_count=$((wait_count + 1))
  done

  if [[ ${wait_count} -ge ${max_drain_wait} ]]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - WARNING: Pipe drain timeout reached, some uploads may not complete"
  fi
}

function send_exit_signal_to_uploader() {
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - Sending a signal to force exit the uploader"
    echo "exit" >>${UPLOAD_PIPE_FILE} &
    echo "exit" >${FORCE_EXIT_FILE}
  fi
}

function exit_on_max_session_reach() {
  if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - Node will be drained since max sessions reached count number ($max_recorded_count)"
    exit
  fi
}

function validate_mp4_file() {
  local video_file="$1"
  local session_id_param="$2"

  if [[ "${video_validation_enabled}" != "true" ]]; then
    return 0
  fi

  if [[ ! -f "${video_file}" ]]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] ERROR: Video file does not exist: ${video_file}"
    return 1
  fi

  # Check if file has moov atom using ffmpeg probe
  if ffmpeg -v error -i "${video_file}" -f null - 2>&1 | grep -q "moov atom not found"; then
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] ERROR: Video file missing moov atom: ${video_file}"
    return 1
  fi

  # Quick validation: check if ffmpeg can read the file
  if ! ffmpeg -v error -i "${video_file}" -t 0.1 -f null - 2>/dev/null; then
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] ERROR: Video file validation failed: ${video_file}"
    return 1
  fi

  echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Video file validation passed: ${video_file}"
  return 0
}

function attempt_fix_mp4_file() {
  local video_file="$1"
  local session_id_param="$2"

  if [[ "${video_fix_corrupted}" != "true" ]]; then
    return 1
  fi

  echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Attempting to fix corrupted MP4 file: ${video_file}"

  local temp_file="${video_file}.temp.mp4"

  # Try to recover the file by remuxing with faststart
  if ffmpeg -v warning -i "${video_file}" -c copy -movflags +faststart "${temp_file}" 2>/dev/null; then
    mv "${temp_file}" "${video_file}"
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Successfully fixed MP4 file: ${video_file}"
    return 0
  else
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Failed to fix MP4 file: ${video_file}"
    rm -f "${temp_file}"
    return 1
  fi
}

function stop_ffmpeg() {
  while true; do
    FFMPEG_PID=$(pgrep -f "ffmpeg -hide_banner" | tr '\n' ' ')
    if [ -n "$FFMPEG_PID" ]; then
      # Single SIGTERM for graceful shutdown - allows FFmpeg to write moov atom
      kill -SIGTERM $FFMPEG_PID
      wait $FFMPEG_PID 2>/dev/null
    fi
    if ! pgrep -f "ffmpeg -hide_banner" >/dev/null; then
      break
    fi
    sleep ${poll_interval}
  done
}

function stop_ffmpeg_graceful_async() {
  local video_file_to_finalize="$1"
  local video_file_name_param="$2"
  local upload_dest_prefix="$3"
  local upload_pipe_file="$4"
  local should_upload="$5"
  local session_id_param="$6"

  (
    # Send single SIGTERM to FFmpeg for graceful shutdown
    # This allows FFmpeg to properly write the moov atom (MP4 metadata)
    FFMPEG_PID=$(pgrep -f "ffmpeg -hide_banner" | tr '\n' ' ')
    if [ -n "$FFMPEG_PID" ]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Sending SIGTERM to FFmpeg PID: $FFMPEG_PID for file: ${video_file_name_param}"
      kill -SIGTERM $FFMPEG_PID

      # Wait for FFmpeg to finish writing
      wait $FFMPEG_PID 2>/dev/null

      # Grace period for metadata finalization
      echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Waiting ${graceful_stop_delay} seconds for video metadata finalization"
      sleep ${graceful_stop_delay}

      # Verify file exists
      if [[ -f "${video_file_to_finalize}" ]]; then
        echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Video file finalized: ${video_file_to_finalize}"

        # Validate MP4 file integrity
        if validate_mp4_file "${video_file_to_finalize}" "${session_id_param}"; then
          # File is valid, proceed with upload
          if [[ "${should_upload}" = "true" ]] && [[ -n "${upload_dest_prefix}" ]] && [[ -n "${upload_pipe_file}" ]]; then
            upload_destination="${upload_dest_prefix}/${video_file_name_param}"
            echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Add to pipe a signal Uploading video to ${upload_destination}"
            echo "${video_file_to_finalize} ${upload_dest_prefix}" >>"${upload_pipe_file}"
          fi
        else
          # Validation failed, attempt to fix
          echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Video validation failed, attempting recovery"
          if attempt_fix_mp4_file "${video_file_to_finalize}" "${session_id_param}"; then
            # Fixed successfully, re-validate and upload
            if validate_mp4_file "${video_file_to_finalize}" "${session_id_param}"; then
              if [[ "${should_upload}" = "true" ]] && [[ -n "${upload_dest_prefix}" ]] && [[ -n "${upload_pipe_file}" ]]; then
                upload_destination="${upload_dest_prefix}/${video_file_name_param}"
                echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] Add to pipe a signal Uploading recovered video to ${upload_destination}"
                echo "${video_file_to_finalize} ${upload_dest_prefix}" >>"${upload_pipe_file}"
              fi
            else
              echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] ERROR: Video file still corrupted after recovery attempt, skipping upload"
            fi
          else
            echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] ERROR: Video file recovery failed, skipping upload"
          fi
        fi
      else
        echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] WARNING: Video file not found after finalization: ${video_file_to_finalize}"
      fi
    fi
  ) &
  local bg_pid=$!
  background_finalization_pids+=($bg_pid)
  echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id_param}] FFmpeg graceful stop initiated in background (PID: ${bg_pid}) for file: ${video_file_name_param}"
}

function stop_recording() {
  local use_async=${1:-true}

  if [[ "${use_async}" = "true" ]]; then
    # Async stop - allows immediate start of new recording
    # Upload will be triggered AFTER FFmpeg finalization in the background
    local should_upload="false"
    if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]]; then
      should_upload="true"
    elif [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -z "${UPLOAD_DESTINATION_PREFIX}" ]]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Upload destination not known since UPLOAD_DESTINATION_PREFIX is not set. Continue without uploading."
    fi

    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Stopping video recording for file: ${video_file_name} (async mode)"
    stop_ffmpeg_graceful_async "${video_file}" "${video_file_name}" "${UPLOAD_DESTINATION_PREFIX}" "${UPLOAD_PIPE_FILE}" "${should_upload}" "${prev_session_id}"
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Video recording stopped (async mode - new session can start immediately)"
  else
    # Sync stop - wait for FFmpeg to fully stop, then upload immediately
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Stopping video recording for file: ${video_file_name} (sync mode)"
    stop_ffmpeg
    echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Video recording stopped (sync mode)"

    if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]]; then
      upload_destination=${UPLOAD_DESTINATION_PREFIX}/${video_file_name}
      echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Add to pipe a signal Uploading video to $upload_destination"
      echo "$video_file ${UPLOAD_DESTINATION_PREFIX}" >>${UPLOAD_PIPE_FILE} &
    elif [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -z "${UPLOAD_DESTINATION_PREFIX}" ]]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Upload destination not known since UPLOAD_DESTINATION_PREFIX is not set. Continue without uploading."
    fi
  fi

  recorded_count=$((recorded_count + 1))
  recording_started="false"
}

function check_if_ffmpeg_running() {
  if pgrep -f "ffmpeg -hide_banner" >/dev/null; then
    return 0
  fi
  return 1
}

function wait_for_file_integrity() {
  retry=0
  if [[ ! -f "${video_file}" ]]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - Video file is not found, might be the recording is not started."
    return 0
  fi
  until ffmpeg -v error -i "${video_file}" -f null -; do
    echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for video file ${video_file} to be ready."
    sleep ${poll_interval}
    retry=$((retry + 1))
    if [[ $retry -ge ${file_ready_max_attempts} ]]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - Video file is not ready after ${file_ready_max_attempts} attempts, skipping..."
      break
    fi
  done
}

function stop_if_recording_inprogress() {
  local use_async=${1:-false}
  if [[ "$recording_started" = "true" ]] || check_if_ffmpeg_running; then
    stop_recording "${use_async}"
  fi
}

function log_node_response() {
  if [[ -n "${session_capabilities}" ]]; then
    jq '.' <<<"${session_capabilities}"
  fi
}

function wait_for_background_finalization() {
  if [ ${#background_finalization_pids[@]} -gt 0 ]; then
    echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for ${#background_finalization_pids[@]} background finalization process(es) to complete"
    for pid in "${background_finalization_pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        echo "$(date -u +"${ts_format}") [${process_name}] - Waiting for background finalization process (PID: $pid)"
        wait "$pid" 2>/dev/null || true
      fi
    done
    echo "$(date -u +"${ts_format}") [${process_name}] - All background finalization processes completed"
  fi
}

function graceful_exit() {
  echo "$(date -u +"${ts_format}") [${process_name}] - Trapped SIGTERM/SIGINT/x so shutting down recorder"
  stop_if_recording_inprogress
  wait_for_background_finalization
  wait_for_pipe_to_drain
  send_exit_signal_to_uploader
  wait_util_uploader_shutdown
}

function graceful_exit_force() {
  graceful_exit
  kill -SIGTERM "$(cat ${SE_SUPERVISORD_PID_FILE})" 2>/dev/null
  echo "$(date -u +"${ts_format}") [${process_name}] - Ready to shutdown the recorder"
  exit 0
}

if [ "${SE_RECORD_AUDIO,,}" = "true" ]; then
  echo "$(date -u +"${ts_format}") [${process_name}] - Audio source arguments: ${SE_AUDIO_SOURCE}"
else
  SE_AUDIO_SOURCE=""
fi

if [[ "${VIDEO_UPLOAD_ENABLED}" != "true" ]] && [[ "${VIDEO_FILE_NAME}" != "auto" ]] && [[ -n "${VIDEO_FILE_NAME}" ]]; then
  trap graceful_exit SIGTERM SIGINT EXIT
  wait_for_display
  video_file="$VIDEO_FOLDER/$VIDEO_FILE_NAME"
  # exec replaces the video.sh process with ffmpeg, this makes easier to pass the process termination signal
  ffmpeg -hide_banner -loglevel warning -threads ${SE_FFMPEG_THREADS:-1} -thread_queue_size 512 \
    -probesize 32M -analyzeduration 0 -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} \
    -i ${DISPLAY} ${SE_AUDIO_SOURCE} -codec:v ${CODEC} ${PRESET:-"-preset veryfast"} \
    -tune zerolatency -crf ${SE_VIDEO_CRF:-28} -maxrate ${SE_VIDEO_MAXRATE:-1000k} -bufsize ${SE_VIDEO_BUFSIZE:-2000k} \
    -pix_fmt yuv420p -movflags +faststart "$video_file" &
  FFMPEG_PID=$!
  if ps -p $FFMPEG_PID >/dev/null; then
    wait $FFMPEG_PID
  fi

else
  trap graceful_exit_force SIGTERM SIGINT EXIT
  create_named_pipe
  wait_for_display
  recording_started="false"
  video_file_name=""
  video_file=""
  prev_session_id=""
  attempts=0
  max_recorded_count=${SE_DRAIN_AFTER_SESSION_COUNT:-0}
  recorded_count=0
  # Track background finalization processes
  declare -a background_finalization_pids

  wait_for_api_respond
  while curl --noproxy "*" -H "${BASIC_AUTH}" -sk --request GET ${NODE_STATUS_ENDPOINT} >"/tmp/status.json"; do
    session_id="$(jq -r "${JQ_SESSION_ID_QUERY}" "/tmp/status.json")"
    if [[ "$session_id" != "null" && "$session_id" != "" && "$session_id" != "reserved" && "$recording_started" = "false" ]]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id}] New session detected"
      session_capabilities="$(jq -r "${JQ_SESSION_CAPABILITIES_QUERY}" "/tmp/status.json")"
      return_list=($(python3 "${VIDEO_CONFIG_DIRECTORY}/video_nodeQuery.py" "${session_id}" "${session_capabilities}"))
      caps_se_video_record="${return_list[0]}"
      video_file_name="${return_list[1]}.mp4"
      if [[ "$caps_se_video_record" = "true" ]]; then
        echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id}] Start recording enabled, video file: ${video_file_name}"
        log_node_response
        video_file="${VIDEO_FOLDER}/$video_file_name"
        echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id}] Starting FFmpeg to record video"
        ffmpeg -hide_banner -loglevel warning -threads ${SE_FFMPEG_THREADS:-1} -thread_queue_size 512 \
          -probesize 32M -analyzeduration 0 -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} \
          -i ${DISPLAY} ${SE_AUDIO_SOURCE} -codec:v ${CODEC} ${PRESET:-"-preset veryfast"} \
          -tune zerolatency -crf ${SE_VIDEO_CRF:-28} -maxrate ${SE_VIDEO_MAXRATE:-1000k} -bufsize ${SE_VIDEO_BUFSIZE:-2000k} \
          -pix_fmt yuv420p -movflags +faststart "$video_file" &
        FFMPEG_PID=$!
        if ps -p $FFMPEG_PID >/dev/null; then
          recording_started="true"
          prev_session_id=$session_id
        fi
        echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${session_id}] Video recording started (FFmpeg PID: ${FFMPEG_PID})"
        sleep ${poll_interval}
      fi
    elif [[ "$session_id" != "$prev_session_id" && "$recording_started" = "true" ]]; then
      stop_recording
      if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]]; then
        echo "$(date -u +"${ts_format}") [${process_name}] - Node will be drained since max sessions reached count number ($max_recorded_count)"
        exit
      fi
    elif [[ $recording_started = "true" ]]; then
      echo "$(date -u +"${ts_format}") [${process_name}] - [Session: ${prev_session_id}] Video recording in progress"
      sleep ${poll_interval}
    else
      sleep ${poll_interval}
    fi
  done
  stop_if_recording_inprogress
  echo "$(date -u +"${ts_format}") [${process_name}] - Node API is not responding now, exiting..."
  echo "$(date -u +"${ts_format}") [${process_name}] - Noted: Set container restart policy to spin up process again for recording another session might come up"
fi
