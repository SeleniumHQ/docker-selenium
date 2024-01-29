#!/bin/bash
if [ ! -z "${SE_REGISTRATION_SECRET}" ];
then
  HEADERS="X-REGISTRATION-SECRET: ${SE_REGISTRATION_SECRET}"
else
  HEADERS="X-REGISTRATION-SECRET;"
fi

if curl -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status; then
    curl -k -X POST ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/se/grid/node/drain --header "${HEADERS}"
    while curl -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status -o /tmp/preStopOutput;
    do
      echo "Node preStop is waiting for current session to be finished if any.\nNode details: \
        .value.message: $(jq -r '.value.message' /tmp/preStopOutput || "unknown"), \
        .value.node.availability: $(jq -r '.value.node.availability' /tmp/preStopOutput || "unknown")"
      sleep 1;
    done
else
    echo "Node is already drained. Shutting down gracefully!"
fi
