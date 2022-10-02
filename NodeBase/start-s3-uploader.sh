#!/usr/bin/env bash

last_session_id=${LAST_SESSION_ID}
full_log_name=${FULL_LOG_NAME}
console_log_name="/tmp/$last_session_id-console.log"
text_log_name="/tmp/$last_session_id-text.log"
network_log_name="/tmp/$last_session_id-network.log"
video_file_name=${VIDEO_FILE_NAME}

echo "session id $last_session_id"
echo "full log name $full_log_name"
echo "console log name $console_log_name"
echo "text log name $text_log_name"
echo "network log name $network_log_name"
echo "pod name ${POD_NAME}"
echo "s3 videos bucket ${S3_VIDEOS_BUCKET}"
echo "s3 logs bucket ${S3_LOGS_BUCKET}"
echo "s3 fulllogs bucket ${S3_FULL_LOGS_BUCKET}"
echo "video file name $video_file_name"

aws s3 cp $video_file_name ${S3_VIDEOS_BUCKET}

if [[ ${POD_NAME} =~ "chrome" || ${POD_NAME} =~ "edge" ]];
then
    echo 'Chrome/Edge browser'
    sed -rn '/Runtime.consoleAPICalled/,/^}*$/p' $full_log_name > $console_log_name
    sed -rn '/\['$last_session_id'\]/,/^}*$/p' $full_log_name > $text_log_name
    sed -rn '/Network./,/^}*$/p' $full_log_name > $network_log_name
    aws s3 cp $full_log_name ${S3_FULL_LOGS_BUCKET}
    aws s3 cp $console_log_name ${S3_LOGS_BUCKET}
    aws s3 cp $text_log_name ${S3_LOGS_BUCKET}
    aws s3 cp $network_log_name ${S3_LOGS_BUCKET}
elif [[ ${POD_NAME} =~ "firefox" ]];
then
    echo 'Firefox browser'
    grep 'console.' $full_log_name | grep -v 'webdriver::server' | grep -v 'Marionette' > $console_log_name
    grep 'webdriver::server' $full_log_name > $text_log_name
    aws s3 cp $full_log_name ${S3_FULL_LOGS_BUCKET}
    aws s3 cp $console_log_name ${S3_LOGS_BUCKET}
    aws s3 cp $text_log_name ${S3_LOGS_BUCKET}
else
    echo 'Unknown browser'
fi