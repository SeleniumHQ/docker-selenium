#!/usr/bin/env bash

SE_VIDEO_FOLDER=${SE_VIDEO_FOLDER:-"/videos"}
UPLOAD_CONFIG_DIRECTORY=${UPLOAD_CONFIG_DIRECTORY:-"/opt/bin"}
UPLOAD_CONFIG_FILE_NAME=${UPLOAD_CONFIG_FILE_NAME:-"config.conf"}
UPLOAD_COMMAND=${UPLOAD_COMMAND:-"copy"}

function consume_force_exit() {
    rm -f ${SE_VIDEO_FOLDER}/force_exit
    echo "Force exit signal consumed"
}
trap consume_force_exit EXIT

while [ ! -p ${SE_VIDEO_FOLDER}/uploadpipe ];
do
      echo "Waiting for ${SE_VIDEO_FOLDER}/uploadpipe to be created"
      sleep 1
done

echo "Waiting for video files put into pipe for proceeding to upload"

while read FILE DESTINATION < ${SE_VIDEO_FOLDER}/uploadpipe
do
    if [ "${FILE}" = "exit" ];
    then
        exit
    else [ "$FILE" != "" ] && [ "$DESTINATION" != "" ];
        echo "Uploading ${FILE} to ${DESTINATION}"
        rclone --config ${UPLOAD_CONFIG_DIRECTORY}/${UPLOAD_CONFIG_FILE_NAME} ${UPLOAD_COMMAND} ${UPLOAD_OPTS} "${FILE}" "${DESTINATION}"
    fi
    if [ -f ${SE_VIDEO_FOLDER}/force_exit ] && [ ! -s ${SE_VIDEO_FOLDER}/uploadpipe ];
    then
        exit
    fi
done

consume_force_exit
