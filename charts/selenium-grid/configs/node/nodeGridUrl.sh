#!/bin/bash

max_time=3

if [ -z "${SE_HUB_HOST:-$SE_ROUTER_HOST}" ] || [ -z "${SE_HUB_PORT:-$SE_ROUTER_PORT}" ]; then
  grid_url=""
else
  if [ -n "${SE_ROUTER_USERNAME}" ] && [ -n "${SE_ROUTER_PASSWORD}" ]; then
    BASIC_AUTH="${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}@"
  fi
  if [ "${SE_SUB_PATH}" = "/" ]; then
    SE_SUB_PATH=""
  fi
  grid_url=${SE_SERVER_PROTOCOL}://${BASIC_AUTH}${SE_HUB_HOST:-$SE_ROUTER_HOST}:${SE_HUB_PORT:-$SE_ROUTER_PORT}${SE_SUB_PATH}
fi

if [ -z "${grid_url}" ]; then
  grid_url="${SE_NODE_GRID_URL}"
fi

if [ -z "${grid_url}" ]; then
  return 0
fi

grid_url_checks=$(curl --noproxy "*" -m ${max_time} -s -k -o /dev/null -w "%{http_code}" ${grid_url})
if [ "${grid_url_checks}" = "401" ]; then
  return ${grid_url_checks}
fi
if [ "${grid_url_checks}" = "404" ]; then
  return ${grid_url_checks}
fi

echo "${grid_url}"
