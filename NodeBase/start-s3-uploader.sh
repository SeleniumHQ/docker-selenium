#!/usr/bin/env bash

if [ ${UPLOAD_TO_S3} = "true" ];
then
  echo 'Uploading $1 to S3 videos bucket ${S3_VIDEOS_BUCKET}'
  aws s3 cp $1 ${S3_VIDEOS_BUCKET}
else
  echo 'Uploading to s3 disabled'
fi