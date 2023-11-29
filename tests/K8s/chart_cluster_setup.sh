#!/bin/bash

echo "Set ENV variables"
CLUSTER_NAME=${CLUSTER_NAME:-"chart-testing"}
RELEASE_NAME=${RELEASE_NAME:-"test"}
SELENIUM_NAMESPACE=${SELENIUM_NAMESPACE:-"selenium"}
KEDA_NAMESPACE=${KEDA_NAMESPACE:-"keda"}
INGRESS_NAMESPACE=${INGRESS_NAMESPACE:-"ingress-nginx"}
SUB_PATH=${SUB_PATH:-"/selenium"}
CHART_PATH=${CHART_PATH:-"charts/selenium-grid"}
TEST_VALUES_PATH=${TEST_VALUES_PATH:-"charts/selenium-grid/ci"}
SELENIUM_GRID_HOST=${SELENIUM_GRID_HOST:-"localhost"}
SELENIUM_GRID_PORT=${SELENIUM_GRID_PORT:-"80"}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-"90s"}
SKIP_CLEANUP=${SKIP_CLEANUP:-"false"} # For debugging purposes, retain the cluster after the test run

# Function to clean up for retry step on workflow
cleanup() {
  if [ "${SKIP_CLEANUP}" = "false" ]; then
    ./tests/K8s/chart_cluster_cleanup.sh
  fi
}

# Function to be executed on command failure
on_failure() {
    local exit_status=$?
    echo "There is step failed with exit status $exit_status"
    cleanup
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

echo "Create Kind cluster"
kind create cluster --wait ${WAIT_TIMEOUT} --name ${CLUSTER_NAME} --config tests/K8s/kind-cluster-config.yaml

echo "Install KEDA core on kind kubernetes cluster"
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.12.1/keda-2.12.1-core.yaml

echo "Install ingress-nginx on kind kubernetes cluster"
kubectl apply -n ${INGRESS_NAMESPACE} -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ${INGRESS_NAMESPACE} \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=${WAIT_TIMEOUT}

echo "Load built local Docker Images into Kind Cluster"
image_list=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep ${NAMESPACE} | grep ${VERSION})
for image in $image_list; do
    kind load docker-image --name ${CLUSTER_NAME} "$image"
done
