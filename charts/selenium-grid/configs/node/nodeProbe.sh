#!/bin/bash

max_time=3
probe_name="Probe.${1:-"Startup"}"
SE_NODE_PORT=${SE_NODE_PORT:-"5555"}
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}
NODE_CONFIG_DIRECTORY=${NODE_CONFIG_DIRECTORY:-"/opt/bin"}

ID=$(echo $RANDOM)
tmp_node_file="/tmp/nodeProbe${ID}"
tmp_grid_file="/tmp/gridProbe${ID}"

function on_exit() {
  rm -rf ${tmp_node_file}
  rm -rf ${tmp_grid_file}
  exit 0
}
trap on_exit EXIT

function init_file() {
  echo "{}" > ${tmp_node_file}
  echo "{}" > ${tmp_grid_file}
}
init_file

function help_message() {
  echo "$(date -u +"${ts_format}") [${probe_name}] - If you believe Node is registered successfully but probe still report this message and fail for a long time. Workaround by set 'global.seleniumGrid.defaultNodeStartupProbe' to 'httpGet' and report us an issue for Chart improvement with your scenario."
}

if curl --noproxy "*" -m ${max_time} -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status -o ${tmp_node_file}; then
  NODE_ID=$(jq -r '.value.node.nodeId' ${tmp_node_file} || "")
  NODE_STATUS=$(jq -r '.value.node.availability' ${tmp_node_file} || "")
  if [ -n "${NODE_ID}" ]; then
    echo "$(date -u +"${ts_format}") [${probe_name}] - Node responds the ID: ${NODE_ID} with status: ${NODE_STATUS}"
  else
    echo "$(date -u +"${ts_format}") [${probe_name}] - Wait for the Node to report its status"
    exit 1
  fi

  return_list=($(bash ${NODE_CONFIG_DIRECTORY}/nodeGridUrl.sh))
  grid_url=${return_list[0]}
  grid_check=${return_list[1]}
  BASIC_AUTH="$(echo -en "${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}" | base64 -w0)"

  if [ -n "${grid_url}" ]; then
    if [ "${grid_check}" = "401" ]; then
      echo "$(date -u +"${ts_format}") [${probe_name}] - Hub/Router requires authentication. Please check SE_ROUTER_USERNAME and SE_ROUTER_PASSWORD."
    elif [ "${grid_check}" = "404" ]; then
      echo "$(date -u +"${ts_format}") [${probe_name}] - Hub/Router endpoint could not be found. Please check the endpoint ${grid_url}"
    fi
  else
    echo "$(date -u +"${ts_format}") [${probe_name}] - There is no configured HUB/ROUTER host or SE_NODE_GRID_URL isn't set. ${probe_name} will not work as expected."
  fi

  curl --noproxy "*" -m ${max_time} -H "Authorization: Basic ${BASIC_AUTH}" -sfk "${grid_url}/status" -o ${tmp_grid_file}
  GRID_NODE_ID=$(jq -e ".value.nodes[].id|select(. == \"${NODE_ID}\")" ${tmp_grid_file} | tr -d '"' || "")
  if [ -n "${GRID_NODE_ID}" ]; then
    echo "$(date -u +"${ts_format}") [${probe_name}] - Grid responds a matched Node ID: ${GRID_NODE_ID}"
  fi

  if [ -n "${NODE_ID}" ] && [ -n "${GRID_NODE_ID}" ] && [ "${NODE_ID}" = "${GRID_NODE_ID}" ]; then
    echo "$(date -u +"${ts_format}") [${probe_name}] - Node ID: ${NODE_ID} is found in the Grid. Node is ready."
    exit 0
  else
    echo "$(date -u +"${ts_format}") [${probe_name}] - Node ID: ${NODE_ID} is not found in the Grid. Node is not ready."
    exit 1
  fi
else
  echo "$(date -u +"${ts_format}") [${probe_name}] - Wait for the Node to report its status"
  exit 1
fi
