#!/bin/bash

echo "Set ENV variables"
CLUSTER_NAME=${CLUSTER_NAME:-"chart-testing"}

cleanup() {
    echo "Clean up kind cluster"
    kind delete clusters ${CLUSTER_NAME}
}

cleanup
