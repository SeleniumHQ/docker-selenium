#!/bin/bash

max_time=3

if [ -n "${SE_ROUTER_USERNAME}" ] && [ -n "${SE_ROUTER_PASSWORD}" ]; then
  BASIC_AUTH="$(echo -en "${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}" | base64 -w0)"
  BASIC_AUTH="Authorization: Basic ${BASIC_AUTH}"
fi

if [ "${SE_SUB_PATH}" = "/" ]; then
  SE_SUB_PATH=""
fi

if [ -z "${SE_HUB_HOST:-$SE_ROUTER_HOST}" ] || [ -z "${SE_HUB_PORT:-$SE_ROUTER_PORT}" ]; then
  grid_url=""
else
  grid_url=${SE_SERVER_PROTOCOL}://${SE_HUB_HOST:-$SE_ROUTER_HOST}:${SE_HUB_PORT:-$SE_ROUTER_PORT}${SE_SUB_PATH}
fi

if [ -z "${grid_url}" ]; then
  grid_url="${SE_NODE_GRID_URL}"
fi

if [ -z "${grid_url}" ]; then
  grid_url="${SE_SERVER_PROTOCOL}://127.0.0.1:4444${SE_SUB_PATH}" # For standalone mode
fi

grid_url_checks=$(curl --noproxy "*" -H "${BASIC_AUTH}" -m ${max_time} -s -k -o /dev/null -w "%{http_code}" ${grid_url})

return_array=("${grid_url}" "${grid_url_checks}")

# stdout the values for other scripts consuming
echo "${return_array[@]}"
