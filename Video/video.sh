#!/usr/bin/env bash

VIDEO_SIZE="${SE_SCREEN_WIDTH}""x""${SE_SCREEN_HEIGHT}"
DISPLAY_CONTAINER_NAME=${DISPLAY_CONTAINER_NAME}
DISPLAY_NUM=${DISPLAY_NUM}
VIDEO_FILE_NAME=${FILE_NAME:-$SE_VIDEO_FILE_NAME}
FRAME_RATE=${FRAME_RATE:-$SE_FRAME_RATE}
CODEC=${CODEC:-$SE_CODEC}
PRESET=${PRESET:-$SE_PRESET}
VIDEO_FOLDER=${SE_VIDEO_FOLDER}
VIDEO_UPLOAD_ENABLED=${VIDEO_UPLOAD_ENABLED:-$SE_VIDEO_UPLOAD_ENABLED}
VIDEO_CONFIG_DIRECTORY=${VIDEO_CONFIG_DIRECTORY:-"/opt/bin"}
UPLOAD_DESTINATION_PREFIX=${UPLOAD_DESTINATION_PREFIX:-$SE_UPLOAD_DESTINATION_PREFIX}
UPLOAD_PIPE_FILE_NAME=${UPLOAD_PIPE_FILE_NAME:-"uploadpipe"}
SE_VIDEO_INTERNAL_UPLOAD=${SE_VIDEO_INTERNAL_UPLOAD:-"false"}
SE_SERVER_PROTOCOL=${SE_SERVER_PROTOCOL:-"http"}
SE_NODE_PORT=${SE_NODE_PORT:-"5555"}

if [ "${SE_VIDEO_INTERNAL_UPLOAD}" = "true" ];
then
    # If using RCLONE in the same container, write signal to /tmp internally
    UPLOAD_PIPE_FILE="/tmp/${UPLOAD_PIPE_FILE_NAME}"
    FORCE_EXIT_FILE="/tmp/force_exit"
else
    # If using external container for uploading, write signal to the video folder
    UPLOAD_PIPE_FILE="${SE_VIDEO_FOLDER}/${UPLOAD_PIPE_FILE_NAME}"
    FORCE_EXIT_FILE="${SE_VIDEO_FOLDER}/force_exit"
fi

function create_pipe() {
    if [[ "${VIDEO_UPLOAD_ENABLED}" != "false" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
        echo "Create pipe if not exists for video upload stream"
        if [[ ! -p ${UPLOAD_PIPE_FILE} ]];
        then
          mkfifo ${UPLOAD_PIPE_FILE}
        fi
    fi
}

function wait_util_uploader_shutdown() {
    max_wait=5
    wait=0
    if [[ "${VIDEO_UPLOAD_ENABLED}" != "false" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
        while [[ -f ${FORCE_EXIT_FILE} ]] && [[ ${wait} -lt ${max_wait} ]];
        do
            echo "Waiting for force exit file to be consumed by external upload container"
            sleep 1
            wait=$((wait+1))
        done
    fi
    if [[ "${VIDEO_UPLOAD_ENABLED}" != "false" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]] && [[ "${SE_VIDEO_INTERNAL_UPLOAD}" = "true" ]];
    then
        while [[ $(pgrep rclone | wc -l) -gt 0 ]]
        do
            echo "Recorder is waiting for RCLONE to finish"
            sleep 1
        done
    fi
    echo "Ready to shutdown the recorder"
}

function send_exit_signal_to_uploader() {
    if [[ "${VIDEO_UPLOAD_ENABLED}" != "false" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
        echo "exit" >> ${UPLOAD_PIPE_FILE} &
        echo "exit" > ${FORCE_EXIT_FILE}
    fi
}

function exit_on_max_session_reach() {
    if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]];
    then
      echo "Node will be drained since max sessions reached count number ($max_recorded_count)"
      exit
    fi
}

function stop_recording() {
    echo "Stopping to record video"
    pkill -INT ffmpeg
    recorded_count=$((recorded_count+1))
    recording_started="false"
    if [[ "${VIDEO_UPLOAD_ENABLED}" != "false" ]] && [[ -n "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
      upload_destination=${UPLOAD_DESTINATION_PREFIX}/${video_file_name}
      echo "Add to pipe a signal Uploading video to $upload_destination"
      echo $video_file ${UPLOAD_DESTINATION_PREFIX} >> ${UPLOAD_PIPE_FILE} &
    elif [[ "${VIDEO_UPLOAD_ENABLED}" != "false" ]] && [[ -z "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
        echo Upload destination not known since UPLOAD_DESTINATION_PREFIX is not set. Continue without uploading.
    fi
}

function check_if_recording_inprogress() {
    if [[ "$recording_started" = "true" ]]
    then
        stop_recording
    fi
}

function graceful_exit() {
    check_if_recording_inprogress
    send_exit_signal_to_uploader
    wait_util_uploader_shutdown
    kill -INT "$(cat /var/run/supervisor/supervisord.pid)"
}

if [[ "${VIDEO_UPLOAD_ENABLED}" != "true" ]] && [[ "${VIDEO_FILE_NAME}" != "auto"  ]] && [[ -n "${VIDEO_FILE_NAME}" ]]; then
  return_code=1
  max_attempts=50
  attempts=0
  echo 'Checking if the display is open...'
  until [[ $return_code -eq 0 ]] || [[ $attempts -eq $max_attempts ]]; do
    xset -display ${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM} b off > /dev/null 2>&1
    return_code=$?
    if [[ $return_code -ne 0 ]]; then
      echo 'Waiting before next display check...'
      sleep 0.5
    fi
    attempts=$((attempts+1))
  done

  # exec replaces the video.sh process with ffmpeg, this makes easier to pass the process termination signal
  exec ffmpeg -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM}.0 -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p "$VIDEO_FOLDER/$VIDEO_FILE_NAME"

else
  create_pipe
  trap graceful_exit SIGTERM SIGINT EXIT
  export DISPLAY=${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM}.0

  max_attempts=600
  attempts=0

  echo Checking if the display is open
  until xset b off || [[ $attempts = "$max_attempts" ]]
  do
      echo Waiting before next display check
      sleep 0.5
      attempts=$((attempts+1))
  done
  if [[ $attempts = "$max_attempts" ]]
  then
      echo Can not open display, exiting.
      exit
  fi

  VIDEO_SIZE=$(xdpyinfo | grep 'dimensions:' | awk '{print $2}')

  recording_started="false"
  video_file_name=""
  video_file=""
  prev_session_id=""
  attempts=0
  max_recorded_count=${SE_DRAIN_AFTER_SESSION_COUNT:-0}
  recorded_count=0

  echo Checking if node API responds
  until curl -sk --request GET ${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT}/status || [[ $attempts = "$max_attempts" ]]
  do
      if [ $(($attempts % 60)) -eq 0 ];
      then
          echo Waiting before next API check
      fi
      sleep 0.5
      attempts=$((attempts+1))
  done
  if [[ $attempts = "$max_attempts" ]]
  then
      echo Can not reach node API, exiting.
      exit
  fi
  while curl -sk --request GET ${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT}/status > /tmp/status.json
  do
      session_id=$(jq -r '.[]?.node?.slots | .[0]?.session?.sessionId' /tmp/status.json)
      if [[ "$session_id" != "null" && "$session_id" != "" && "$recording_started" = "false" ]]
      then
        echo "Session: $session_id is created"
        caps_se_video_record=$(bash ${VIDEO_CONFIG_DIRECTORY}/video_graphQLQuery.sh "$session_id")
        if [[ -f "/tmp/graphQL_$session_id.json" ]]; then
          cat "/tmp/graphQL_$session_id.json"; echo
        fi
        echo "se:recordVideo value is: $caps_se_video_record"
      fi
      if [[ "$session_id" != "null" && "$session_id" != "" && "$recording_started" = "false" && "$caps_se_video_record" = "true" ]]
      then
          video_file_name="$session_id.mp4"
          video_file="${SE_VIDEO_FOLDER}/$video_file_name"
          echo "Starting to record video"
          ffmpeg -nostdin -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY} -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p $video_file &
          recording_started="true"
          echo "Video recording started"
      elif [[ "$session_id" != "$prev_session_id" && "$recording_started" = "true" ]]
      then
          stop_recording
          if [[ $max_recorded_count -gt 0 ]] && [[ $recorded_count -ge $max_recorded_count ]];
          then
            echo "Node will be drained since max sessions reached count number ($max_recorded_count)"
            exit
          fi
      elif [[ $recording_started = "true" ]]
      then
          echo "Video recording in progress "
          sleep 1
      else
          sleep 1
      fi
      prev_session_id=$session_id
  done
  echo "Node API is not responding, exiting."
  exit
fi
