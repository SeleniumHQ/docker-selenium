#!/usr/bin/env bash

SE_VIDEO_FOLDER=${SE_VIDEO_FOLDER:-"/videos"}
UPLOAD_COMMAND=${UPLOAD_COMMAND:-"cp"}
UPLOAD_RETAIN_LOCAL_FILE=${SE_UPLOAD_RETAIN_LOCAL_FILE:-"false"}
SE_VIDEO_UPLOAD_BATCH_CHECK=${SE_VIDEO_UPLOAD_BATCH_CHECK:-"10"}

if [[ -z "${AWS_REGION}" ]] || [[ -z "${AWS_ACCESS_KEY_ID}" ]] || [[ -z "${AWS_SECRET_ACCESS_KEY}" ]];
then
    echo "AWS credentials needed to provide for configuring AWS CLI"
fi

aws configure set region ${AWS_REGION} --profile s3-profile
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID} --profile s3-profile
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY} --profile s3-profile
aws configure --profile s3-profile

function consume_force_exit() {
    for pid in "${list_upload_pid[@]}";
    do
        wait ${pid}
    done
    rm -rf ${SE_VIDEO_FOLDER}/force_exit
    echo "Force exit signal consumed"
}
trap consume_force_exit EXIT

if [ "${UPLOAD_RETAIN_LOCAL_FILE}" = "false" ];
then
  echo "UPLOAD_RETAIN_LOCAL_FILE is set to false, force to use command: move"
  UPLOAD_COMMAND="mv"
fi

while [ ! -p ${SE_VIDEO_FOLDER}/uploadpipe ];
do
      echo "Waiting for ${SE_VIDEO_FOLDER}/uploadpipe to be created"
      sleep 1
done

echo "Waiting for video files put into pipe for proceeding to upload"

list_upload_pid=()
while read FILE DESTINATION < ${SE_VIDEO_FOLDER}/uploadpipe
do
    if [ "${FILE}" = "exit" ];
    then
        exit
    elif [ "$FILE" != "" ] && [ "$DESTINATION" != "" ];
    then
        echo "Uploading ${FILE} to ${DESTINATION}"
        aws s3 ${UPLOAD_COMMAND} "${FILE}" "${DESTINATION}" &
        list_upload_pid+=($!)
    else
        # Wait for a batch of processes to finish
        if [ ${#list_upload_pid[@]} -eq ${SE_VIDEO_UPLOAD_BATCH_CHECK} ]
        then
            for pid in "${list_upload_pid[@]}";
            do
                wait ${pid}
            done
            list_upload_pid=()
        fi
    fi

    if [ -f ${SE_VIDEO_FOLDER}/force_exit ] && [ ! -s ${SE_VIDEO_FOLDER}/uploadpipe ];
    then
        exit
    fi
done

consume_force_exit
