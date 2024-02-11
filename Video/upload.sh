#!/usr/bin/env bash

SE_VIDEO_FOLDER=${SE_VIDEO_FOLDER:-"/videos"}
UPLOAD_CONFIG_DIRECTORY=${UPLOAD_CONFIG_DIRECTORY:-"/opt/bin"}
UPLOAD_CONFIG_FILE_NAME=${UPLOAD_CONFIG_FILE_NAME:-"upload.conf"}
UPLOAD_COMMAND=${UPLOAD_COMMAND:-"copy"}
UPLOAD_RETAIN_LOCAL_FILE=${SE_UPLOAD_RETAIN_LOCAL_FILE:-"false"}
UPLOAD_PIPE_FILE_NAME=${UPLOAD_PIPE_FILE_NAME:-"uploadpipe"}
SE_VIDEO_INTERNAL_UPLOAD=${SE_VIDEO_INTERNAL_UPLOAD:-"false"}
VIDEO_UPLOAD_ENABLED=${VIDEO_UPLOAD_ENABLED:-SE_VIDEO_UPLOAD_ENABLED}
SE_VIDEO_UPLOAD_BATCH_CHECK=${SE_VIDEO_UPLOAD_BATCH_CHECK:-"10"}

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

if [ "${UPLOAD_RETAIN_LOCAL_FILE}" = "false" ];
then
  echo "UPLOAD_RETAIN_LOCAL_FILE is set to false, force to use RCLONE command: move"
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

function graceful_exit() {
    for pid in "${list_rclone_pid[@]}";
    do
        wait ${pid}
    done
    rm -rf ${FORCE_EXIT_FILE}
    echo "Uploader is ready to shutdown"
}
trap graceful_exit EXIT

while [ ! -p ${UPLOAD_PIPE_FILE} ];
do
      echo "Waiting for ${UPLOAD_PIPE_FILE} to be created"
      sleep 1
done

echo "Waiting for video files put into pipe for proceeding to upload"

rename_rclone_env

list_rclone_pid=()
while read FILE DESTINATION < ${UPLOAD_PIPE_FILE}
do
    if [ "${FILE}" = "exit" ];
    then
        exit
    elif [ "$FILE" != "" ] && [ "$DESTINATION" != "" ];
    then
        echo "Uploading ${FILE} to ${DESTINATION}"
        rclone --config ${UPLOAD_CONFIG_DIRECTORY}/${UPLOAD_CONFIG_FILE_NAME} ${UPLOAD_COMMAND} ${UPLOAD_OPTS} "${FILE}" "${DESTINATION}" &
        list_rclone_pid+=($!)
    else
        # Wait for a batch rclone processes to finish
        if [ ${#list_rclone_pid[@]} -eq ${SE_VIDEO_UPLOAD_BATCH_CHECK} ]
        then
            for pid in "${list_rclone_pid[@]}";
            do
                wait ${pid}
            done
            list_rclone_pid=()
        fi
    fi
done

graceful_exit
