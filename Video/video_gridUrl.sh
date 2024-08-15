#!/bin/bash

max_time=3

if [ -n "${SE_ROUTER_USERNAME}" ] && [ -n "${SE_ROUTER_PASSWORD}" ]; then
  BASIC_AUTH="${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}@"
fi
if [ "${SE_SUB_PATH}" = "/" ]; then
  SE_SUB_PATH=""
fi

if [ -z "${SE_HUB_HOST:-$SE_ROUTER_HOST}" ] || [ -z "${SE_HUB_PORT:-$SE_ROUTER_PORT}" ]; then
  grid_url=""
else
  grid_url=${SE_SERVER_PROTOCOL}://${BASIC_AUTH}${SE_HUB_HOST:-$SE_ROUTER_HOST}:${SE_HUB_PORT:-$SE_ROUTER_PORT}${SE_SUB_PATH}
fi

if [ -z "${grid_url}" ] && [ -n "${DISPLAY_CONTAINER_NAME}" ] && [ "${SE_VIDEO_RECORD_STANDALONE}" = "true" ]; then
  grid_url="${SE_SERVER_PROTOCOL}://${BASIC_AUTH}${DISPLAY_CONTAINER_NAME}:${SE_NODE_PORT:-4444}${SE_SUB_PATH}" # For standalone mode
fi

if [ -z "${grid_url}" ]; then
  grid_url="${SE_NODE_GRID_URL}"
fi

if [[ ${grid_url} == */ ]]; then
  grid_url="${grid_url%/}"
fi

echo "${grid_url}"
