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
poll_interval=${SE_VIDEO_POLL_INTERVAL:-1}
max_attempts=${SE_VIDEO_WAIT_ATTEMPTS:-50}
process_name="video.recorder"

if [ "${SE_VIDEO_RECORD_STANDALONE}" = "true" ]; then
  JQ_SESSION_ID_QUERY=".value.nodes[]?.slots[]?.session?.sessionId"
  SE_NODE_PORT=${SE_NODE_PORT:-"4444"}
  NODE_STATUS_ENDPOINT="$(/opt/bin/video_gridUrl.sh)/status"
else
  JQ_SESSION_ID_QUERY=".[]?.node?.slots | .[0]?.session?.sessionId"
  SE_NODE_PORT=${SE_NODE_PORT:-"5555"}
  NODE_STATUS_ENDPOINT="${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT}/status"
fi

if [ -d "${VIDEO_FOLDER}" ]; then
  echo "$(date +%FT%T%Z) [${process_name}] - Video folder exists: ${VIDEO_FOLDER}"
else
  echo "$(date +%FT%T%Z) [${process_name}] - Video folder does not exist: ${VIDEO_FOLDER}. Due to permission, folder name could not be changed via environment variable. Exiting..."
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
      echo "$(date +%FT%T%Z) [${process_name}] - Created named pipe ${UPLOAD_PIPE_FILE}"
    fi
  fi
}

function wait_for_display() {
  DISPLAY=${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM}.0
  export DISPLAY=${DISPLAY}
  echo "$(date +%FT%T%Z) [${process_name}] - Waiting for the display ${DISPLAY} is open"
  until xset b off >/dev/null 2>&1; do
    sleep ${poll_interval}
  done
  VIDEO_SIZE=$(xdpyinfo | grep 'dimensions:' | awk '{print $2}')
  echo "$(date +%FT%T%Z) [${process_name}] - Display ${DISPLAY} is open with dimensions ${VIDEO_SIZE}"
}

function check_if_api_respond() {
  endpoint_checks=$(curl --noproxy "*" -sk -o /dev/null -w "%{http_code}" "${NODE_STATUS_ENDPOINT}")
  if [[ "${endpoint_checks}" != "200" ]]; then
    return 1
  fi
  return 0
}

function wait_for_api_respond() {
  echo "$(date +%FT%T%Z) [${process_name}] - Waiting for Node endpoint responds"
  until check_if_api_respond; do
    sleep ${poll_interval}
  done
  return 0
}

function wait_util_uploader_shutdown() {
  max_wait=5
  wait=0
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]] && [[ "${VIDEO_INTERNAL_UPLOAD}" != "true" ]]; then
    while [[ -f ${FORCE_EXIT_FILE} ]] && [[ ${wait} -lt ${max_wait} ]]; do
      echo "exit" >>${UPLOAD_PIPE_FILE} &
      echo "$(date +%FT%T%Z) [${process_name}] - Waiting for force exit file to be consumed by external upload container"
      sleep 1
      wait=$((wait + 1))
    done
  fi
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]] && [[ "${VIDEO_INTERNAL_UPLOAD}" = "true" ]]; then
    while [[ $(pgrep rclone | wc -l) -gt 0 ]]; do
      echo "exit" >>${UPLOAD_PIPE_FILE} &
      echo "$(date +%FT%T%Z) [${process_name}] - Recorder is waiting for RCLONE to finish"
      sleep 1
    done
  fi
}

function send_exit_signal_to_uploader() {
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    echo "$(date +%FT%T%Z) [${process_name}] - Sending a signal to force exit the uploader"
    echo "exit" >>${UPLOAD_PIPE_FILE} &
    echo "exit" >${FORCE_EXIT_FILE}
  fi
}

function exit_on_max_session_reach() {
  if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]]; then
    echo "$(date +%FT%T%Z) [${process_name}] - Node will be drained since max sessions reached count number ($max_recorded_count)"
    exit
  fi
}

function stop_ffmpeg() {
  while true; do
    FFMPEG_PID=$(pgrep -f ffmpeg | tr '\n' ' ')
    if [ -n "$FFMPEG_PID" ]; then
      kill -SIGTERM $FFMPEG_PID
      wait $FFMPEG_PID
    fi
    if ! pgrep -f ffmpeg >/dev/null; then
      break
    fi
    sleep ${poll_interval}
  done
}

function stop_recording() {
  stop_ffmpeg
  echo "$(date +%FT%T%Z) [${process_name}] - Video recording stopped"
  recorded_count=$((recorded_count + 1))
  if [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    upload_destination=${UPLOAD_DESTINATION_PREFIX}/${video_file_name}
    echo "$(date +%FT%T%Z) [${process_name}] - Add to pipe a signal Uploading video to $upload_destination"
    echo "$video_file ${UPLOAD_DESTINATION_PREFIX}" >>${UPLOAD_PIPE_FILE} &
  elif [[ "${VIDEO_UPLOAD_ENABLED}" = "true" ]] && [[ -z "${UPLOAD_DESTINATION_PREFIX}" ]]; then
    echo "$(date +%FT%T%Z) [${process_name}] - Upload destination not known since UPLOAD_DESTINATION_PREFIX is not set. Continue without uploading."
  fi
  recording_started="false"
}

function check_if_ffmpeg_running() {
  if pgrep -f ffmpeg >/dev/null; then
    return 0
  fi
  return 1
}

function stop_if_recording_inprogress() {
  if [[ "$recording_started" = "true" ]] || check_if_ffmpeg_running; then
    stop_recording
  fi
}

function log_node_response() {
  if [[ -f "/tmp/graphQL_$session_id.json" ]]; then
    jq '.' "/tmp/graphQL_$session_id.json"
  fi
}

function graceful_exit() {
  echo "$(date +%FT%T%Z) [${process_name}] - Trapped SIGTERM/SIGINT/x so shutting down recorder"
  stop_if_recording_inprogress
  send_exit_signal_to_uploader
  wait_util_uploader_shutdown
  kill -SIGTERM "$(cat ${SE_SUPERVISORD_PID_FILE})" 2>/dev/null
  echo "$(date +%FT%T%Z) [${process_name}] - Ready to shutdown the recorder"
  exit 0
}

if [[ "${VIDEO_UPLOAD_ENABLED}" != "true" ]] && [[ "${VIDEO_FILE_NAME}" != "auto" ]] && [[ -n "${VIDEO_FILE_NAME}" ]]; then
  trap graceful_exit SIGTERM SIGINT EXIT
  wait_for_display
  # exec replaces the video.sh process with ffmpeg, this makes easier to pass the process termination signal
  ffmpeg -hide_banner -loglevel warning -flags low_delay -threads 2 -fflags nobuffer+genpts -strict experimental -y -f x11grab \
    -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY} -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p "$VIDEO_FOLDER/$VIDEO_FILE_NAME" &
  wait $!

else
  trap graceful_exit SIGTERM SIGINT EXIT
  create_named_pipe
  wait_for_display
  recording_started="false"
  video_file_name=""
  video_file=""
  prev_session_id=""
  attempts=0
  max_recorded_count=${SE_DRAIN_AFTER_SESSION_COUNT:-0}
  recorded_count=0

  wait_for_api_respond
  while curl --noproxy "*" -sk --request GET ${NODE_STATUS_ENDPOINT} >/tmp/status.json; do
    session_id=$(jq -r "${JQ_SESSION_ID_QUERY}" /tmp/status.json)
    if [[ "$session_id" != "null" && "$session_id" != "" && "$session_id" != "reserved" && "$recording_started" = "false" ]]; then
      echo "$(date +%FT%T%Z) [${process_name}] - Session: $session_id is created"
      return_list=($(bash ${VIDEO_CONFIG_DIRECTORY}/video_graphQLQuery.sh "$session_id"))
      caps_se_video_record=${return_list[0]}
      video_file_name="${return_list[1]}.mp4"
      echo "$(date +%FT%T%Z) [${process_name}] - Start recording: $caps_se_video_record, video file name: $video_file_name"
      log_node_response
    fi
    if [[ "$session_id" != "null" && "$session_id" != "" && "$session_id" != "reserved" && "$recording_started" = "false" && "$caps_se_video_record" = "true" ]]; then
      video_file="${VIDEO_FOLDER}/$video_file_name"
      echo "$(date +%FT%T%Z) [${process_name}] - Starting to record video"
      ffmpeg -hide_banner -loglevel warning -flags low_delay -threads 2 -fflags nobuffer+genpts -strict experimental -y -f x11grab \
        -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY} -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p "$video_file" &
      recording_started="true"
      echo "$(date +%FT%T%Z) [${process_name}] - Video recording started"
      sleep ${poll_interval}
    elif [[ "$session_id" != "$prev_session_id" && "$recording_started" = "true" ]]; then
      stop_recording
      if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]]; then
        echo "$(date +%FT%T%Z) [${process_name}] - Node will be drained since max sessions reached count number ($max_recorded_count)"
        exit
      fi
    elif [[ $recording_started = "true" ]]; then
      echo "$(date +%FT%T%Z) [${process_name}] - Video recording in progress"
      sleep ${poll_interval}
    else
      sleep ${poll_interval}
    fi
    prev_session_id=$session_id
  done
  echo "$(date +%FT%T%Z) [${process_name}] - Node API is not responding now, exiting..."
fi
