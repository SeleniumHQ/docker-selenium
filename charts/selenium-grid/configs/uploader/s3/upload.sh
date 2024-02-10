#!/usr/bin/env bash

SE_VIDEO_FOLDER=${SE_VIDEO_FOLDER:-"/videos"}

if [[ -z "${AWS_REGION}" ]] || [[ -z "${AWS_ACCESS_KEY_ID}" ]] || [[ -z "${AWS_SECRET_ACCESS_KEY}" ]];
then
    echo "AWS credentials needed to provide for configuring AWS CLI"
fi

aws configure set region ${AWS_REGION} --profile s3-profile
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID} --profile s3-profile
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY} --profile s3-profile
aws configure --profile s3-profile

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
        aws s3 cp "${FILE}" "${DESTINATION}"
    fi
    if [ -f ${SE_VIDEO_FOLDER}/force_exit ] && [ ! -s ${SE_VIDEO_FOLDER}/uploadpipe ];
    then
        exit
    fi
done

consume_force_exit
