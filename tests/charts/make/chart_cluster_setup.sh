#!/bin/bash
set -o xtrace

echo "Set ENV variables"
CLUSTER=${CLUSTER:-"minikube"}
CLUSTER_NAME=${CLUSTER_NAME:-"chart-testing"}
RELEASE_NAME=${RELEASE_NAME:-"test"}
SELENIUM_NAMESPACE=${SELENIUM_NAMESPACE:-"selenium"}
KEDA_NAMESPACE=${KEDA_NAMESPACE:-"keda"}
INGRESS_NAMESPACE=${INGRESS_NAMESPACE:-"ingress-nginx"}
SUB_PATH=${SUB_PATH:-"/selenium"}
CHART_PATH=${CHART_PATH:-"charts/selenium-grid"}
TEST_VALUES_PATH=${TEST_VALUES_PATH:-"tests/charts/ci"}
SELENIUM_GRID_HOST=${SELENIUM_GRID_HOST:-"localhost"}
SELENIUM_GRID_PORT=${SELENIUM_GRID_PORT:-"80"}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-"90s"}
SKIP_CLEANUP=${SKIP_CLEANUP:-"false"} # For debugging purposes, retain the cluster after the test run
KUBERNETES_VERSION=${KUBERNETES_VERSION:-$(curl -L -s https://dl.k8s.io/release/stable.txt)}
CNI=${CNI:-"calico"} # auto, calico, cilium
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-"docker"} # docker, containerd, cri-o
SERVICE_MESH=${SERVICE_MESH:-"false"}

# Function to clean up for retry step on workflow
cleanup() {
  if [ "${SKIP_CLEANUP}" = "false" ]; then
    ./tests/charts/make/chart_cluster_cleanup.sh
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

if [ "${CLUSTER}" = "kind" ]; then
  echo "Start Kind cluster"
  kind create cluster --image kindest/node:${KUBERNETES_VERSION} --wait ${WAIT_TIMEOUT} --name ${CLUSTER_NAME} --config tests/charts/config/kind-cluster.yaml
elif [ "${CLUSTER}" = "minikube" ]; then
  echo "Start Minikube cluster"
  sudo chmod 777 /tmp
  export CHANGE_MINIKUBE_NONE_USER=true
  sudo -SE minikube start --vm-driver=none \
  --kubernetes-version=${KUBERNETES_VERSION} --network-plugin=cni --cni=${CNI} --container-runtime=${CONTAINER_RUNTIME} --wait=all
  sudo chown -R $USER $HOME/.kube $HOME/.minikube
  if [ "${SERVICE_MESH}" = "true" ]; then
    minikube addons enable istio-provisioner
    minikube addons enable istio
  fi
fi

if [ "${CLUSTER}" = "kind" ]; then
  echo "Load built local Docker Images into Kind Cluster"
  image_list=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep ${NAMESPACE} | grep ${BUILD_DATE:-$VERSION})
  for image in $image_list; do
      kind load docker-image --name ${CLUSTER_NAME} "$image"
  done
fi
