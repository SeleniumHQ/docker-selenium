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
AUTOSCALING_POLL_INTERVAL=${AUTOSCALING_POLL_INTERVAL:-20}
SKIP_CLEANUP=${SKIP_CLEANUP:-"false"} # For debugging purposes, retain the cluster after the test run
CHART_CERT_PATH=${CHART_CERT_PATH:-"${CHART_PATH}/certs/selenium.pem"}
SSL_CERT_DIR=${SSL_CERT_DIR:-"/etc/ssl/certs"}
VIDEO_TAG=${VIDEO_TAG:-"latest"}
SE_ENABLE_TRACING=${SE_ENABLE_TRACING:-"false"}
SE_FULL_DISTRIBUTED_MODE=${SE_FULL_DISTRIBUTED_MODE:-"false"}
HOSTNAME_ADDRESS=${HOSTNAME_ADDRESS:-"selenium-grid.local"}
SE_ENABLE_INGRESS_HOSTNAME=${SE_ENABLE_INGRESS_HOSTNAME:-"false"}

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
    kubectl describe all -n ${SELENIUM_NAMESPACE} >> tests/tests/describe_all_resources_${MATRIX_BROWSER}.txt
    kubectl describe pod -n ${SELENIUM_NAMESPACE} >> tests/tests/describe_all_resources_${MATRIX_BROWSER}.txt
    echo "There is step failed with exit status $exit_status"
    cleanup
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR EXIT

touch tests/tests/describe_all_resources_${MATRIX_BROWSER}.txt

if [ -f .env ]
then
    export "$(cat .env | xargs)"
else
    export UPLOAD_ENABLED=false
fi
export RELEASE_NAME=${RELEASE_NAME}
RECORDER_VALUES_FILE=${TEST_VALUES_PATH}/base-recorder-values.yaml
envsubst < ${RECORDER_VALUES_FILE} > ./tests/tests/base-recorder-values.yaml
RECORDER_VALUES_FILE=./tests/tests/base-recorder-values.yaml

HELM_COMMAND_SET_IMAGES=" \
--set global.seleniumGrid.imageRegistry=${NAMESPACE} \
--set global.seleniumGrid.imageTag=${VERSION} \
--set global.seleniumGrid.nodesImageTag=${VERSION} \
--set global.seleniumGrid.videoImageTag=${VIDEO_TAG} \
--set autoscaling.scaledOptions.pollingInterval=${AUTOSCALING_POLL_INTERVAL} \
--set tracing.enabled=${SE_ENABLE_TRACING} \
--set isolateComponents=${SE_FULL_DISTRIBUTED_MODE} \
"

if [ "${SE_ENABLE_INGRESS_HOSTNAME}" = "true" ]; then
  if [[ ! $(cat /etc/hosts) == *"${HOSTNAME_ADDRESS}"* ]]; then
    sudo -- sh -c -e "echo \"$(hostname -i) ${HOSTNAME_ADDRESS}\" >> /etc/hosts"
  fi
  ping -c 2 ${HOSTNAME_ADDRESS}
  HELM_COMMAND_SET_IMAGES="${HELM_COMMAND_SET_IMAGES} \
  --set ingress.hostname=${HOSTNAME_ADDRESS} \
  "
  SELENIUM_GRID_HOST=${HOSTNAME_ADDRESS}
else
  HELM_COMMAND_SET_IMAGES="${HELM_COMMAND_SET_IMAGES} \
  --set global.K8S_PUBLIC_IP=${SELENIUM_GRID_HOST} \
  "
fi

if [ "${SELENIUM_GRID_AUTOSCALING}" = "true" ]; then
  HELM_COMMAND_SET_AUTOSCALING=" \
  --set autoscaling.enableWithExistingKEDA=${SELENIUM_GRID_AUTOSCALING} \
  --set autoscaling.scaledOptions.minReplicaCount=${SELENIUM_GRID_AUTOSCALING_MIN_REPLICA} \
  "
fi

HELM_COMMAND_SET_BASE_VALUES=" \
--values ${TEST_VALUES_PATH}/base-auth-ingress-values.yaml \
--values ${RECORDER_VALUES_FILE} \
--values ${TEST_VALUES_PATH}/base-resources-values.yaml \
"

if [ "${SELENIUM_GRID_PROTOCOL}" = "https" ]; then
  HELM_COMMAND_SET_BASE_VALUES="${HELM_COMMAND_SET_BASE_VALUES} \
  --values ${TEST_VALUES_PATH}/base-tls-values.yaml \
  "
fi

HELM_COMMAND_SET_BASE_VALUES="${HELM_COMMAND_SET_BASE_VALUES} \
--values ${TEST_VALUES_PATH}/${MATRIX_BROWSER}-values.yaml \
"

HELM_COMMAND_ARGS="${RELEASE_NAME} \
${HELM_COMMAND_SET_BASE_VALUES} \
${HELM_COMMAND_SET_AUTOSCALING} \
${HELM_COMMAND_SET_IMAGES} \
${CHART_PATH} --namespace ${SELENIUM_NAMESPACE} --create-namespace"

echo "Render manifests YAML for this deployment"
helm template --debug ${HELM_COMMAND_ARGS} > tests/tests/cluster_deployment_manifests_${MATRIX_BROWSER}.yaml

echo "Deploy Selenium Grid Chart"
helm upgrade --install ${HELM_COMMAND_ARGS}

kubectl get pods -A

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
export SELENIUM_GRID_TEST_HEADLESS=${SELENIUM_GRID_TEST_HEADLESS:-"false"}
./tests/bootstrap.sh ${MATRIX_BROWSER}

echo "Get pods status"
kubectl get pods -n ${SELENIUM_NAMESPACE}

echo "Get all resources in all namespaces"
kubectl get all -A >> tests/tests/describe_all_resources_${MATRIX_BROWSER}.txt

cleanup
