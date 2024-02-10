#!/usr/bin/env bash

SE_VIDEO_FOLDER=${SE_VIDEO_FOLDER:-"/videos"}
UPLOAD_CONFIG_DIRECTORY=${UPLOAD_CONFIG_DIRECTORY:-"/opt/bin"}
UPLOAD_CONFIG_FILE_NAME=${UPLOAD_CONFIG_FILE_NAME:-"upload.conf"}
UPLOAD_COMMAND=${UPLOAD_COMMAND:-"copy"}
UPLOAD_RETAIN_LOCAL_FILE=${SE_UPLOAD_RETAIN_LOCAL_FILE:-"false"}
UPLOAD_PIPE_FILE_NAME=${UPLOAD_PIPE_FILE_NAME:-"uploadpipe"}
SE_VIDEO_INTERNAL_UPLOAD=${SE_VIDEO_INTERNAL_UPLOAD:-"true"}
VIDEO_UPLOAD_ENABLED=${VIDEO_UPLOAD_ENABLED:-SE_VIDEO_UPLOAD_ENABLED}

function consume_force_exit() {
    rm -f ${FORCE_EXIT_FILE}
    echo "Force exit signal consumed"
}

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

if [ "${SE_VIDEO_INTERNAL_UPLOAD}" = "true" ];
then
    UPLOAD_PIPE_FILE="/tmp/${UPLOAD_PIPE_FILE_NAME}"
    FORCE_EXIT_FILE="/tmp/force_exit"
else
    UPLOAD_PIPE_FILE="${SE_VIDEO_FOLDER}/${UPLOAD_PIPE_FILE_NAME}"
    FORCE_EXIT_FILE="${SE_VIDEO_FOLDER}/force_exit"
fi

trap consume_force_exit EXIT

while [ ! -p ${UPLOAD_PIPE_FILE} ];
do
      echo "Waiting for ${UPLOAD_PIPE_FILE} to be created"
      sleep 1
done

echo "Waiting for video files put into pipe for proceeding to upload"

rename_rclone_env

while read FILE DESTINATION < ${UPLOAD_PIPE_FILE}
do
    if [ "${FILE}" = "exit" ];
    then
        exit
    else [ "$FILE" != "" ] && [ "$DESTINATION" != "" ];
        echo "Uploading ${FILE} to ${DESTINATION}"
        rclone --config ${UPLOAD_CONFIG_DIRECTORY}/${UPLOAD_CONFIG_FILE_NAME} ${UPLOAD_COMMAND} ${UPLOAD_OPTS} "${FILE}" "${DESTINATION}"
        if [ $? -eq 0 ] && [ "${UPLOAD_RETAIN_LOCAL_FILE}" = "false" ];
        then
          rm -rf $FILE
        fi
    fi
    if [ -f ${FORCE_EXIT_FILE} ] && [ ! -s ${UPLOAD_PIPE_FILE} ];
    then
        exit
    fi
done

consume_force_exit
