#!/bin/bash

if [ -z "${SE_HUB_HOST:-$SE_ROUTER_HOST}" ] || [ -z "${SE_HUB_PORT:-$SE_ROUTER_PORT}" ]; then
  graphql_url=""
else
  if [ -n "${SE_ROUTER_USERNAME}" ] && [ -n "${SE_ROUTER_PASSWORD}" ]; then
    BASIC_AUTH="${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}@"
  fi

  if [[ ${SE_SUB_PATH} == */ ]]; then
    GRAPHQL_ENDPOINT="${SE_SUB_PATH}graphql"
  else
    GRAPHQL_ENDPOINT="${SE_SUB_PATH}/graphql"
  fi

  if [[ ${GRAPHQL_ENDPOINT} == /* ]]; then
    GRAPHQL_ENDPOINT="${GRAPHQL_ENDPOINT}"
  else
    GRAPHQL_ENDPOINT="/${GRAPHQL_ENDPOINT}"
  fi

  graphql_url="${SE_SERVER_PROTOCOL}://${BASIC_AUTH}${SE_HUB_HOST:-${SE_ROUTER_HOST}}:${SE_HUB_PORT:-${SE_ROUTER_PORT}}${GRAPHQL_ENDPOINT}"
fi

echo "${graphql_url}"
