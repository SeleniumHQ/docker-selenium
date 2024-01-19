#!/bin/bash
if curl -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status; then
    curl -k -X POST ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/se/grid/node/drain --header 'X-REGISTRATION-SECRET;'
    while curl -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status; do sleep 1; done
else
    echo "Node is already drained. Shutting down gracefully!"
fi
