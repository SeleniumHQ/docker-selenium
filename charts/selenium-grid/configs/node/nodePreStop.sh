#!/bin/bash

probe_name="lifecycle.${1:-"preStop"}"
SE_NODE_PORT=${SE_NODE_PORT:-"5555"}
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}
NODE_CONFIG_DIRECTORY=${NODE_CONFIG_DIRECTORY:-"/opt/bin"}

max_time=3
retry_time=5

ID=$(echo $RANDOM)
tmp_node_file="/tmp/nodeProbe${ID}"

function on_exit() {
  rm -rf ${tmp_node_file}
  echo "$(date -u +"${ts_format}") [${probe_name}] - Exiting Node ${probe_name}..."
  exit 0
}
trap on_exit EXIT

function init_file() {
  echo "{}" > ${tmp_node_file}
}
init_file

# Set headers if Node Registration Secret is set
if [ ! -z "${SE_REGISTRATION_SECRET}" ]; then
  HEADERS="X-REGISTRATION-SECRET: ${SE_REGISTRATION_SECRET}"
else
  HEADERS="X-REGISTRATION-SECRET;"
fi

function signal_hub_to_drain_node() {
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
    echo "$(date -u +"${ts_format}") [${probe_name}] - Signaling Hub/Router to drain node"
    curl --noproxy "*" -m ${max_time} -k -X POST -H "Authorization: Basic ${BASIC_AUTH}" ${grid_url}/se/grid/distributor/node/${NODE_ID}/drain --header "${HEADERS}"
  else
    echo "$(date -u +"${ts_format}") [${probe_name}] - There is no configured HUB/ROUTER host or SE_NODE_GRID_URL isn't set. ${probe_name} ignores to send drain request to upstream."
  fi
}

function signal_node_to_drain() {
    echo "$(date -u +"${ts_format}") [${probe_name}] - Signaling Node to drain itself"
    curl --noproxy "*" -m ${max_time} -k -X POST ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/se/grid/node/drain --header "${HEADERS}"
}

if curl --noproxy "*" -m ${max_time} -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status > ${tmp_node_file}; then
    NODE_ID=$(jq -r '.value.node.nodeId' ${tmp_node_file} || "")
    if [ -n "${NODE_ID}" ]; then
      echo "$(date -u +"${ts_format}") [${probe_name}] - Current Node ID is: ${NODE_ID}"
      signal_hub_to_drain_node
      echo
    fi
    signal_node_to_drain
    # Wait for the current session to be finished if any
    while true; do
      # Attempt the cURL request and capture the exit status
      endpoint_http_code=$(curl --noproxy "*" --retry ${retry_time} -m ${max_time} -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status -o ${tmp_node_file} -w "%{http_code}")
      endpoint_status=$?
      echo "$(date -u +"${ts_format}") [${probe_name}] - Fetch the Node status via cURL with exit status: ${endpoint_status}, HTTP code: ${endpoint_http_code}"

      SLOT_HAS_SESSION=$(jq -e ".value.node.slots[]|select(.session != null).id.id" ${tmp_node_file} | tr -d '"' || "")
      if [ -z "${SLOT_HAS_SESSION}" ]; then
        echo "$(date -u +"${ts_format}") [${probe_name}] - There is no session running. Node is ready to be terminated."
        echo "$(date -u +"${ts_format}") [${probe_name}] - $(cat ${tmp_node_file} || "")"
        echo
        exit 0
      else
        echo "$(date -u +"${ts_format}") [${probe_name}] - Node ${probe_name} is waiting for current session on slot ${SLOT_HAS_SESSION} to be finished. Node details: message: $(jq -r '.value.message' ${tmp_node_file} || "unknown"), availability: $(jq -r '.value.node.availability' ${tmp_node_file} || "unknown")"
        sleep 2;
      fi

      # If the cURL command failed, break the loop
      if [ ${endpoint_status} -ne 0 ] || [ "${endpoint_http_code}" != "200" ]; then
        echo "$(date -u +"${ts_format}") [${probe_name}] - Node endpoint returned status ${endpoint_http_code:-"exit ${endpoint_status}"}, probably Node draining complete!"
        break
      fi
    done
else
    echo "$(date -u +"${ts_format}") [${probe_name}] - Node is already drained. Shutting down gracefully!"
fi
