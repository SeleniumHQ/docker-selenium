#!/bin/bash

echo "Set ENV variables"
CLUSTER=${CLUSTER:-"minikube"}
CLUSTER_NAME=${CLUSTER_NAME:-"chart-testing"}

cleanup() {
  if [ "${CLUSTER}" = "kind" ]; then
    echo "Clean up Kind cluster"
    kind delete clusters ${CLUSTER_NAME}
  elif [ "${CLUSTER}" = "minikube" ]; then
    echo "Clean up Minikube cluster"
    sudo -SE minikube delete
  fi
}

cleanup
