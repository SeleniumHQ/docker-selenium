#!/usr/bin/env bash

source /opt/bin/logger.sh

VIDEO_SIZE="${SE_SCREEN_WIDTH}""x""${SE_SCREEN_HEIGHT}"
DISPLAY_CONTAINER_NAME=${DISPLAY_CONTAINER_NAME}
DISPLAY_NUM=${DISPLAY_NUM}
VIDEO_FILE_NAME=${FILE_NAME:-$SE_VIDEO_FILE_NAME}
FRAME_RATE=${FRAME_RATE:-$SE_FRAME_RATE}
CODEC=${CODEC:-$SE_CODEC}
PRESET=${PRESET:-$SE_PRESET}
VIDEO_FOLDER=${VIDEO_FOLDER}
SE_VIDEO_SESSION_SUBFOLDER=${SE_VIDEO_SESSION_SUBFOLDER:-"false"}
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

auth_header=()
if [ -n "${SE_ROUTER_USERNAME}" ] && [ -n "${SE_ROUTER_PASSWORD}" ]; then
  BASIC_AUTH="$(echo -en "${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}" | base64 -w0)"
  auth_header=(-H "Authorization: Basic ${BASIC_AUTH}")
fi

# Set headers if Node Registration Secret is set
if [ ! -z "${SE_REGISTRATION_SECRET}" ]; then
  HEADERS="X-REGISTRATION-SECRET: ${SE_REGISTRATION_SECRET}"
else
  HEADERS="X-REGISTRATION-SECRET;"
fi

if [ -d "${VIDEO_FOLDER}" ]; then
  log_info "Video folder exists: ${VIDEO_FOLDER}"
else
  log_error "Video folder does not exist: ${VIDEO_FOLDER}. Due to permission, folder name could not be changed via environment variable. Exiting..."
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
      log_info "Created named pipe ${UPLOAD_PIPE_FILE}"
    fi
  fi
}

function wait_for_display() {
  DISPLAY=${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM}.0
  export DISPLAY=${DISPLAY}
  log_info "Waiting for the display ${DISPLAY} is open"
  until xset b off >/dev/null 2>&1; do
    sleep ${poll_interval}
  done
  if [ -z "$SE_SCREEN_WIDTH" -o -z "$SE_SCREEN_HEIGHT" ]; then
    VIDEO_SIZE=$(xdpyinfo | grep 'dimensions:' | awk '{print $2}')
  fi
  log_info "Display ${DISPLAY} is open with dimensions ${VIDEO_SIZE}"
}

function check_if_api_respond() {
  endpoint_checks=$(curl --noproxy "*" "${auth_header[@]}" -sk -o /dev/null -w "%{http_code}" "${NODE_STATUS_ENDPOINT}")
  if [[ "${endpoint_checks}" != "200" ]]; then
    python3 /opt/bin/validate_endpoint.py "${NODE_STATUS_ENDPOINT}"
    return 1
  fi
  return 0
}

function wait_for_api_respond() {
  log_info "Waiting for Node endpoint responds"
  until check_if_api_respond; do
    sleep ${poll_interval}
  done
  log_info "Node endpoint is responding now. Proceeding next steps..."
  return 0
}

function wait_util_uploader_shutdown() {
  wait=0
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]] && [[ "${VIDEO_INTERNAL_UPLOAD}" != "true" ]]; then
    while [[ -f ${FORCE_EXIT_FILE} ]] && [[ ${wait} -lt ${wait_uploader_shutdown_max_attempts} ]]; do
      echo "exit" >>${UPLOAD_PIPE_FILE} &
      log_info "Waiting for force exit file to be consumed by external upload container"
      sleep ${poll_interval}
      wait=$((wait + 1))
    done
  fi
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]] && [[ "${VIDEO_INTERNAL_UPLOAD}" = "true" ]]; then
    while [[ $(pgrep rclone | wc -l) -gt 0 ]]; do
      echo "exit" >>${UPLOAD_PIPE_FILE} &
      log_info "Recorder is waiting for RCLONE to finish"
      sleep ${poll_interval}
    done
  fi
}

function send_exit_signal_to_uploader() {
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    log_info "Sending a signal to force exit the uploader"
    echo "exit" >>${UPLOAD_PIPE_FILE} &
    echo "exit" >${FORCE_EXIT_FILE}
  fi
}

function exit_on_max_session_reach() {
  if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]]; then
    log_info "Node will be drained since max sessions reached count number ($max_recorded_count)"
    exit
  fi
}

function stop_ffmpeg() {
  while true; do
    FFMPEG_PID=$(pgrep -f "ffmpeg -hide_banner" | tr '\n' ' ')
    if [ -n "$FFMPEG_PID" ]; then
      kill -SIGTERM $FFMPEG_PID
      wait $FFMPEG_PID
    fi
    if ! pgrep -f "ffmpeg -hide_banner" >/dev/null; then
      break
    fi
    sleep ${poll_interval}
  done
}

function stop_recording() {
  stop_ffmpeg
  log_info "Video recording stopped"
  recorded_count=$((recorded_count + 1))
  recording_started="false"
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    upload_destination=${UPLOAD_DESTINATION_PREFIX}/${video_file_name}
    log_info "Add to pipe a signal Uploading video to $upload_destination"
    echo "$video_file ${UPLOAD_DESTINATION_PREFIX}" >>${UPLOAD_PIPE_FILE} &
  elif [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -z "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    log_info "Upload destination not known since UPLOAD_DESTINATION_PREFIX is not set. Continue without uploading."
  fi
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
    log_info "Video file is not found, might be the recording is not started."
    return 0
  fi
  until ffmpeg -v error -i "${video_file}" -f null -; do
    log_info "Waiting for video file ${video_file} to be ready."
    sleep ${poll_interval}
    retry=$((retry + 1))
    if [[ $retry -ge ${file_ready_max_attempts} ]]; then
      log_info "Video file is not ready after ${file_ready_max_attempts} attempts, skipping..."
      break
    fi
  done
}

function stop_if_recording_inprogress() {
  if [[ "$recording_started" = "true" ]] || check_if_ffmpeg_running; then
    stop_recording
  fi
}

function log_node_response() {
  if [[ -n "${session_capabilities}" ]]; then
    jq '.' <<<"${session_capabilities}"
  fi
}

function graceful_exit() {
  log_info "Trapped SIGTERM/SIGINT/x so shutting down recorder"
  stop_if_recording_inprogress
  send_exit_signal_to_uploader
  wait_util_uploader_shutdown
}

_graceful_exit_done=false
function graceful_exit_force() {
  if [[ "$_graceful_exit_done" = "true" ]]; then
    return
  fi
  _graceful_exit_done=true
  graceful_exit
  # Supervisord signaling is delegated to the Python controller (video_recorder.py)
  # which handles it uniformly for both shell and event-driven modes.
  log_info "Ready to shutdown the recorder"
  exit 0
}

if [ "${SE_RECORD_AUDIO,,}" = "true" ]; then
  log_info "Audio source arguments: ${SE_AUDIO_SOURCE}"
else
  SE_AUDIO_SOURCE=""
fi

if [[ "${VIDEO_UPLOAD_ENABLED}" != "true" ]] && [[ "${VIDEO_FILE_NAME}" != "auto" ]] && [[ -n "${VIDEO_FILE_NAME}" ]]; then
  trap graceful_exit_force SIGTERM SIGINT EXIT
  wait_for_display
  video_file="$VIDEO_FOLDER/$VIDEO_FILE_NAME"
  # exec replaces the video.sh process with ffmpeg, this makes easier to pass the process termination signal
  ffmpeg -hide_banner -loglevel warning -threads ${SE_FFMPEG_THREADS:-1} -thread_queue_size 512 \
    -probesize 32M -analyzeduration 0 -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} \
    -i ${DISPLAY} ${SE_AUDIO_SOURCE} -codec:v ${CODEC} ${PRESET:-"-preset veryfast"} \
    -tune zerolatency -crf ${SE_VIDEO_CRF:-28} -maxrate ${SE_VIDEO_MAXRATE:-1000k} -bufsize ${SE_VIDEO_BUFSIZE:-2000k} \
    -pix_fmt yuv420p -movflags frag_keyframe+empty_moov+default_base_moof "$video_file" &
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
  skipped_session_id=""
  attempts=0
  max_recorded_count=${SE_DRAIN_AFTER_SESSION_COUNT:-0}
  recorded_count=0

  wait_for_api_respond
  while curl --noproxy "*" "${auth_header[@]}" -sk --request GET ${NODE_STATUS_ENDPOINT} >"/tmp/status.json"; do
    session_id="$(jq -r "${JQ_SESSION_ID_QUERY}" "/tmp/status.json")"
    if [[ "$session_id" != "null" && "$session_id" != "" && "$session_id" != "reserved" && "$recording_started" = "false" && "$session_id" != "$skipped_session_id" ]]; then
      log_info "Session: $session_id is created"
      session_capabilities="$(jq -r "${JQ_SESSION_CAPABILITIES_QUERY}" "/tmp/status.json")"
      return_list=($(python3 "${VIDEO_CONFIG_DIRECTORY}/video_nodeQuery.py" "${session_id}" "${session_capabilities}"))
      caps_se_video_record="${return_list[0]}"
      video_file_name="${return_list[1]}.mp4"
      if [[ "$caps_se_video_record" = "true" ]]; then
        log_info "Start recording: $caps_se_video_record, video file name: $video_file_name"
        log_node_response
        if [[ "${SE_VIDEO_SESSION_SUBFOLDER}" = "true" ]]; then
          # Group each recording under its session id. If the session id is empty for any reason,
          # fall back to the Node container/Pod name so the video still lands in a unique subfolder.
          subfolder_key="${session_id}"
          if [ -z "${subfolder_key}" ] || [ "${subfolder_key}" = "null" ]; then
            subfolder_key="${SE_NODE_CONTAINER_NAME}"
          fi
          if [ -n "${subfolder_key}" ]; then
            video_dir="${VIDEO_FOLDER}/${subfolder_key}"
            mkdir -p "${video_dir}"
            log_info "Created session subfolder: ${video_dir}"
          else
            video_dir="${VIDEO_FOLDER}"
          fi
        else
          video_dir="${VIDEO_FOLDER}"
        fi
        video_file="${video_dir}/$video_file_name"
        log_info "Starting to record video"
        ffmpeg -hide_banner -loglevel warning -threads ${SE_FFMPEG_THREADS:-1} -thread_queue_size 512 \
          -probesize 32M -analyzeduration 0 -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} \
          -i ${DISPLAY} ${SE_AUDIO_SOURCE} -codec:v ${CODEC} ${PRESET:-"-preset veryfast"} \
          -tune zerolatency -crf ${SE_VIDEO_CRF:-28} -maxrate ${SE_VIDEO_MAXRATE:-1000k} -bufsize ${SE_VIDEO_BUFSIZE:-2000k} \
          -pix_fmt yuv420p -movflags frag_keyframe+empty_moov+default_base_moof "$video_file" &
        FFMPEG_PID=$!
        if ps -p $FFMPEG_PID >/dev/null; then
          recording_started="true"
          prev_session_id=$session_id
        fi
        log_info "Video recording started"
      else
        log_info "Recording skipped for session: $session_id (se:recordVideo=false)"
        skipped_session_id="$session_id"
      fi
      sleep ${poll_interval}
    elif [[ "$session_id" != "$prev_session_id" && "$recording_started" = "true" ]]; then
      stop_recording
      if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]]; then
        log_info "Node will be drained since max sessions reached count number ($max_recorded_count)"
        exit
      fi
    elif [[ $recording_started = "true" ]]; then
      log_info "Video recording in progress"
      sleep ${poll_interval}
    else
      sleep ${poll_interval}
    fi
  done
  stop_if_recording_inprogress
  log_warn "Node API is not responding now, exiting..."
  log_info "Noted: Set container restart policy to spin up process again for recording another session might come up"
fi
