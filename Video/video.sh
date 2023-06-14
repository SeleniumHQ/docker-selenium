#!/bin/sh

VIDEO_SIZE="${SE_SCREEN_WIDTH}""x""${SE_SCREEN_HEIGHT}"
DISPLAY_CONTAINER_NAME=${DISPLAY_CONTAINER_NAME}
DISPLAY_NUM=${DISPLAY_NUM}
FILE_NAME=${FILE_NAME}
FRAME_RATE=${FRAME_RATE:-$SE_FRAME_RATE}
CODEC=${CODEC:-$SE_CODEC}
PRESET=${PRESET:-$SE_PRESET}
VIDEO_FOLDER=${SE_VIDEO_FOLDER}

return_code=1
max_attempts=50
attempts=0
echo 'Checking if the display is open...'
until [ $return_code -eq 0 -o $attempts -eq $max_attempts ]; do
	xset -display ${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM} b off > /dev/null 2>&1
	return_code=$?
	if [ $return_code -ne 0 ]; then
		echo 'Waiting before next display check...'
		sleep 0.5
	fi
	attempts=$((attempts+1))
done

# exec replaces the video.sh process with ffmpeg, this makes easier to pass the process termination signal
exec ffmpeg -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM}.0 -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p "$VIDEO_FOLDER/$FILE_NAME"

