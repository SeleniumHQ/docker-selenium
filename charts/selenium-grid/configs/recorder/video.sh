#!/usr/bin/env bash

UPLOAD_ENABLED=${UPLOAD_ENABLED:-"false"}

function create_pipe() {
    if [[ "${UPLOAD_ENABLED}" != "false" ]] && [[ ! -z "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
        echo "Create pipe if not exists for video upload stream"
        if [ ! -p ${SE_VIDEO_FOLDER}/uploadpipe ];
        then
          mkfifo ${SE_VIDEO_FOLDER}/uploadpipe
        fi
    fi
}
create_pipe

function wait_util_force_exit_consume() {
    if [[ "${UPLOAD_ENABLED}" != "false" ]] && [[ ! -z "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
        while [[ -f ${SE_VIDEO_FOLDER}/force_exit ]]
        do
            echo "Waiting for force exit file to be consumed by uploader"
            sleep 1
        done
        echo "Ready to shutdown the recorder"
    fi
}

function add_exit_signal() {
    if [[ "${UPLOAD_ENABLED}" != "false" ]] && [[ ! -z "${UPLOAD_DESTINATION_PREFIX}" ]];
    then
        echo "exit" >> ${SE_VIDEO_FOLDER}/uploadpipe &
        echo "exit" > ${SE_VIDEO_FOLDER}/force_exit
    fi
}

function exit_on_max_session_reach() {
    if [ $max_recorded_count -gt 0 ] && [ $recorded_count -ge $max_recorded_count ];
    then
      echo "Node will be drained since max sessions reached count number ($max_recorded_count)"
      exit
    fi
}

function finish {
    add_exit_signal
    wait_util_force_exit_consume
    kill -INT `cat /var/run/supervisor/supervisord.pid`
}
trap finish EXIT

FRAME_RATE=${FRAME_RATE:-$SE_FRAME_RATE}
CODEC=${CODEC:-$SE_CODEC}
PRESET=${PRESET:-$SE_PRESET}
DISPLAY_CONTAINER_NAME=${DISPLAY_CONTAINER_NAME:-"localhost"}
export DISPLAY=${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM}.0

max_attempts=600
attempts=0
echo Checking if the display is open
until xset b off || [[ $attempts = $max_attempts ]]
do
    echo Waiting before next display check
    sleep 0.5
    attempts=$((attempts+1))
done
if [[ $attempts = $max_attempts ]]
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
until curl -sk --request GET ${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT}/status || [[ $attempts = $max_attempts ]]
do
    echo Waiting before next API check
    sleep 0.5
    attempts=$((attempts+1))
done
if [[ $attempts = $max_attempts ]]
then
    echo Can not reach node API, exiting.
    exit
fi
while curl -sk --request GET ${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT}/status > /tmp/status.json
do
    session_id=$(jq -r '.[]?.node?.slots | .[0]?.session?.sessionId' /tmp/status.json)
    echo $session_id
    if [[ "$session_id" != "null" && "$session_id" != "" && "$recording_started" = "false" ]]
    then
        video_file_name="$session_id.mp4"
        video_file="${SE_VIDEO_FOLDER}/$video_file_name"
        echo "Starting to record video"
        ffmpeg -nostdin -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY} -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p $video_file &
        recording_started="true"
        echo "Video recording started"
    elif [[ "$session_id" != "$prev_session_id" && "$recording_started" = "true" ]]
    then
        echo "Stopping to record video"
        pkill -INT ffmpeg
        recorded_count=$((recorded_count+1))
        recording_started="false"
        if [[ "${UPLOAD_ENABLED}" != "false" ]] && [[ ! -z "${UPLOAD_DESTINATION_PREFIX}" ]];
        then
          upload_destination=${UPLOAD_DESTINATION_PREFIX}/${video_file_name}
          echo "Uploading video to $upload_destination"
          echo $video_file ${UPLOAD_DESTINATION_PREFIX} >> ${SE_VIDEO_FOLDER}/uploadpipe &
        elif [[ "${UPLOAD_ENABLED}" != "false" ]] && [[ -z "${UPLOAD_DESTINATION_PREFIX}" ]];
        then
            echo Upload destination not known since UPLOAD_DESTINATION_PREFIX is not set. Continue without uploading.
        fi
        if [ $max_recorded_count -gt 0 ] && [ $recorded_count -ge $max_recorded_count ];
        then
          echo "Node will be drained since max sessions reached count number ($max_recorded_count)"
          exit
        fi

    elif [[ $recording_started = "true" ]]
    then
        echo "Video recording in progress"
        sleep 1
    else
        echo "No session in progress"
        sleep 1
    fi
    prev_session_id=$session_id
done
echo "Node API is not responding, exiting."
