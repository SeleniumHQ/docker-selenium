#!/usr/bin/env bash


echo "s3 videos bucket ${S3_VIDEOS_BUCKET}"
echo "video file name ${VIDEO_FILE_NAME}"

aws s3 cp ${VIDEO_FILE_NAME} ${S3_VIDEOS_BUCKET}