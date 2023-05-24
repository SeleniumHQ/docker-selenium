#!/usr/bin/env bash

if [ "${UPLOAD_TO_S3}" = "true" ];
then
  s3_location="${S3_VIDEOS_BUCKET}/$2"
  echo "Uploading $1 $2 to S3 videos bucket ${S3_VIDEOS_BUCKET} $s3_location"
  s3cmd --access_key="${AWS_ACCESS_KEY_ID}" --secret_key="${AWS_SECRET_ACCESS_KEY}" put $1 $s3_location
else
  echo "Uploading to s3 disabled"
fi