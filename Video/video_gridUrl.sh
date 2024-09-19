#!/bin/bash

max_time=3

if [ "${SE_SUB_PATH}" = "/" ]; then
  SE_SUB_PATH=""
fi

grid_url="${SE_NODE_GRID_URL}"
if [ -n "${SE_HUB_HOST:-$SE_ROUTER_HOST}" ] && [ -n "${SE_HUB_PORT:-$SE_ROUTER_PORT}" ]; then
  grid_url=${SE_SERVER_PROTOCOL}://${SE_HUB_HOST:-$SE_ROUTER_HOST}:${SE_HUB_PORT:-$SE_ROUTER_PORT}${SE_SUB_PATH}
elif [ -n "${DISPLAY_CONTAINER_NAME}" ] && [ "${SE_VIDEO_RECORD_STANDALONE}" = "true" ]; then
  grid_url="${SE_SERVER_PROTOCOL}://${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT:-4444}${SE_SUB_PATH}" # For standalone mode
fi

if [[ ${grid_url} == */ ]]; then
  grid_url="${grid_url%/}"
fi

echo "${grid_url}"
