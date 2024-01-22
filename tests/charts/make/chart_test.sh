#!/bin/bash
mkdir -p tests/tests
set -o xtrace

echo "Set ENV variables"
CLUSTER_NAME=${CLUSTER_NAME:-"chart-testing"}
RELEASE_NAME=${RELEASE_NAME:-"test"}
SELENIUM_NAMESPACE=${SELENIUM_NAMESPACE:-"selenium"}
KEDA_NAMESPACE=${KEDA_NAMESPACE:-"keda"}
INGRESS_NAMESPACE=${INGRESS_NAMESPACE:-"ingress-nginx"}
SUB_PATH=${SUB_PATH:-"/selenium"}
CHART_PATH=${CHART_PATH:-"charts/selenium-grid"}
TEST_VALUES_PATH=${TEST_VALUES_PATH:-"tests/charts/ci"}
SELENIUM_GRID_PROTOCOL=${SELENIUM_GRID_PROTOCOL:-"http"}
SELENIUM_GRID_HOST=${SELENIUM_GRID_HOST:-"localhost"}
SELENIUM_GRID_PORT=${SELENIUM_GRID_PORT:-"80"}
MATRIX_BROWSER=${1:-"NodeChrome"}
SELENIUM_GRID_AUTOSCALING=${2:-"true"}
SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=${3:-"0"}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-"90s"}
HUB_CHECKS_INTERVAL=${HUB_CHECKS_INTERVAL:-45}
HUB_CHECKS_MAX_ATTEMPTS=${HUB_CHECKS_MAX_ATTEMPTS:-6}
WEB_DRIVER_WAIT_TIMEOUT=${WEB_DRIVER_WAIT_TIMEOUT:-120}
SKIP_CLEANUP=${SKIP_CLEANUP:-"false"} # For debugging purposes, retain the cluster after the test run
CHART_CERT_PATH=${CHART_CERT_PATH:-"${CHART_PATH}/certs/selenium.pem"}
SSL_CERT_DIR=${SSL_CERT_DIR:-"/etc/ssl/certs"}
VIDEO_TAG=${VIDEO_TAG:-"latest"}
UPLOADER_TAG=${UPLOADER_TAG:-"latest"}

cleanup() {
  if [ "${SKIP_CLEANUP}" = "false" ]; then
    echo "Clean up chart release and namespace"
    helm delete ${RELEASE_NAME} --namespace ${SELENIUM_NAMESPACE}
    kubectl delete namespace ${SELENIUM_NAMESPACE}
  fi
}

# Function to be executed on command failure
on_failure() {
    local exit_status=$?
    echo "Describe all resources in the ${SELENIUM_NAMESPACE} namespace for debugging purposes"
    kubectl describe all -n ${SELENIUM_NAMESPACE} > tests/tests/describe_all_resources_${MATRIX_BROWSER}.txt
    echo "There is step failed with exit status $exit_status"
    cleanup
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

HELM_COMMAND_SET_AUTOSCALING=""
if [ "${SELENIUM_GRID_AUTOSCALING}" = "true" ]; then
  HELM_COMMAND_SET_AUTOSCALING="--values ${TEST_VALUES_PATH}/DeploymentAutoScaling-values.yaml \
  --set autoscaling.enableWithExistingKEDA=${SELENIUM_GRID_AUTOSCALING} \
  --set autoscaling.scaledOptions.minReplicaCount=${SELENIUM_GRID_AUTOSCALING_MIN_REPLICA}"
fi

HELM_COMMAND_SET_TLS=""
if [ "${SELENIUM_GRID_PROTOCOL}" = "https" ]; then
  HELM_COMMAND_SET_TLS="--values ${TEST_VALUES_PATH}/tls-values.yaml"
fi

HELM_COMMAND_ARGS="${RELEASE_NAME} \
--values ${TEST_VALUES_PATH}/auth-ingress-values.yaml \
--values ${TEST_VALUES_PATH}/tracing-values.yaml \
${HELM_COMMAND_SET_AUTOSCALING} \
${HELM_COMMAND_SET_TLS} \
--values ${TEST_VALUES_PATH}/${MATRIX_BROWSER}-values.yaml \
--set global.seleniumGrid.imageRegistry=${NAMESPACE} \
--set global.seleniumGrid.imageTag=${VERSION} \
--set global.seleniumGrid.nodesImageTag=${VERSION} \
--set global.seleniumGrid.videoImageTag=${VIDEO_TAG} \
--set global.seleniumGrid.uploaderImageTag=${UPLOADER_TAG} \
${CHART_PATH} --namespace ${SELENIUM_NAMESPACE} --create-namespace"

echo "Render manifests YAML for this deployment"
helm template --debug ${HELM_COMMAND_ARGS} > tests/tests/cluster_deployment_manifests_${MATRIX_BROWSER}.yaml

echo "Deploy Selenium Grid Chart"
helm upgrade --install ${HELM_COMMAND_ARGS}

echo "Run Tests"
export CHART_CERT_PATH=$(readlink -f ${CHART_CERT_PATH})
export SELENIUM_GRID_PROTOCOL=${SELENIUM_GRID_PROTOCOL}
export SELENIUM_GRID_HOST=${SELENIUM_GRID_HOST}
export SELENIUM_GRID_PORT=${SELENIUM_GRID_PORT}""${SUB_PATH}
export SELENIUM_GRID_AUTOSCALING=${SELENIUM_GRID_AUTOSCALING}
export SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=${SELENIUM_GRID_AUTOSCALING_MIN_REPLICA}
export RUN_IN_DOCKER_COMPOSE=true
export HUB_CHECKS_INTERVAL=${HUB_CHECKS_INTERVAL}
export HUB_CHECKS_MAX_ATTEMPTS=${HUB_CHECKS_MAX_ATTEMPTS}
export WEB_DRIVER_WAIT_TIMEOUT=${WEB_DRIVER_WAIT_TIMEOUT}
./tests/bootstrap.sh ${MATRIX_BROWSER}

echo "Get pods status"
kubectl get pods -n ${SELENIUM_NAMESPACE}

echo "Get all resources in the ${SELENIUM_NAMESPACE} namespace"
kubectl get all -n ${SELENIUM_NAMESPACE} > tests/tests/describe_all_resources_${MATRIX_BROWSER}.txt

cleanup
