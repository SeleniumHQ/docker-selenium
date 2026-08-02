#!/usr/bin/env bash
set -o xtrace

# Test the Dynamic Grid manifests in kubernetes/DynamicGrid against locally built images.
# The manifests are deployed as documented, only the image references are rewritten to the
# tag produced by `make build`, so what is tested is what users are told to apply.
#
# Usage: ./tests/k8s/make/dynamic_grid_test.sh [Standalone|HubNode]

MODE=${1:-Standalone}

echo "Set ENV variables"
NAMESPACE=${NAMESPACE:-"selenium"}
VERSION=${VERSION:-"latest"}
PLATFORMS=${PLATFORMS:-"linux/amd64"}
SELENIUM_NAMESPACE=${SELENIUM_NAMESPACE:-"selenium"}
MANIFEST_PATH=${MANIFEST_PATH:-"kubernetes/DynamicGrid"}
RENDER_PATH=${RENDER_PATH:-"tests/tests/dynamic-grid-${MODE}"}
TEST_VALUES_PATH=${TEST_VALUES_PATH:-"tests/charts/ci"}
ASSETS_HOST_PATH=${ASSETS_HOST_PATH:-"/tmp/selenium/assets"}
GRID_USERNAME=${GRID_USERNAME:-"admin"}
GRID_PASSWORD=${GRID_PASSWORD:-"admin"}
GRID_LOCAL_PORT=${GRID_LOCAL_PORT:-"4444"}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-"300s"}
GRID_READY_ATTEMPTS=${GRID_READY_ATTEMPTS:-"60"}
SKIP_CLEANUP=${SKIP_CLEANUP:-"false"} # For debugging purposes, retain the deployment after the test run
ASSETS_PERMISSION_JOB="selenium-assets-permission"
PORT_FORWARD_PID=""

case "${MODE}" in
Standalone)
  MODE_PATH="Standalone"
  GRID_SERVICE="selenium-standalone-kubernetes"
  DEPLOYMENTS="selenium-standalone-kubernetes"
  GRID_IMAGES="standalone-kubernetes"
  ;;
HubNode)
  MODE_PATH="Hub_Node"
  GRID_SERVICE="selenium-hub"
  DEPLOYMENTS="selenium-hub selenium-node-kubernetes"
  GRID_IMAGES="hub node-kubernetes"
  ;;
*)
  echo "Unknown mode ${MODE}, expected Standalone or HubNode"
  exit 1
  ;;
esac

# Browser images the Dynamic Grid starts as Jobs. Microsoft Edge is only built for AMD64.
BROWSER_IMAGES="standalone-chromium standalone-firefox"
if [ "${PLATFORMS}" = "linux/amd64" ]; then
  BROWSER_IMAGES="${BROWSER_IMAGES} standalone-edge"
fi

wait_for_terminated() {
  # Wait until no pods are in "Terminating" state
  while true; do
    terminating_pods=$(kubectl get pods -n ${SELENIUM_NAMESPACE} --no-headers 2>/dev/null | grep Terminating | wc -l)
    if [ ${terminating_pods} -eq 0 ]; then
      echo "No pods in 'Terminating' state."
      break
    else
      echo "Waiting for ${terminating_pods} pod(s) to terminate..."
      sleep 2
    fi
  done
}

stop_port_forward() {
  if [ -n "${PORT_FORWARD_PID}" ]; then
    kill ${PORT_FORWARD_PID} 2>/dev/null || true
    PORT_FORWARD_PID=""
  fi
}

cleanup() {
  stop_port_forward
  # Get the list of pods
  pods=$(kubectl get pods -n ${SELENIUM_NAMESPACE} -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  # Iterate over the pods and print their logs
  for pod in ${pods}; do
    echo "Logs for pod ${pod}"
    kubectl logs -n ${SELENIUM_NAMESPACE} ${pod} --all-containers --tail=10000 >tests/tests/pod_logs_dynamic_grid_${MODE}_${pod}.txt || true
  done
  if [ "${SKIP_CLEANUP}" = "false" ]; then
    echo "Clean up Dynamic Grid ${MODE} deployment"
    kubectl delete job/${ASSETS_PERMISSION_JOB} -n ${SELENIUM_NAMESPACE} --ignore-not-found=true
    kubectl delete -n ${SELENIUM_NAMESPACE} -f ${RENDER_PATH}/${MODE_PATH} --ignore-not-found=true
    kubectl delete -n ${SELENIUM_NAMESPACE} -f ${RENDER_PATH}/BaseConfig --ignore-not-found=true
    wait_for_terminated
  fi
}

# Function to be executed on command failure
on_failure() {
  local exit_status=$?
  kubectl get pods -n "${SELENIUM_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | while read pod; do
    echo "Logs for pod ${pod}"
    kubectl logs -n "${SELENIUM_NAMESPACE}" "${pod}" --all-containers --tail=10000
  done
  echo "Get all resources in the ${SELENIUM_NAMESPACE} namespace, browser Jobs included"
  kubectl get all -n ${SELENIUM_NAMESPACE} >>tests/tests/describe_dynamic_grid_${MODE}.txt
  kubectl describe all -n ${SELENIUM_NAMESPACE} >>tests/tests/describe_dynamic_grid_${MODE}.txt
  kubectl describe pod -n ${SELENIUM_NAMESPACE} >>tests/tests/describe_dynamic_grid_${MODE}.txt
  echo "There is step failed with exit status ${exit_status}"
  cleanup
  exit ${exit_status}
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

echo "Check the images under test are built locally"
for image in ${GRID_IMAGES} ${BROWSER_IMAGES}; do
  if ! docker image inspect ${NAMESPACE}/${image}:${VERSION} >/dev/null 2>&1; then
    echo "${NAMESPACE}/${image}:${VERSION} is not yet built. Please run 'make build'"
    false
  fi
done

echo "Render the Dynamic Grid manifests against the images built locally"
rm -rf ${RENDER_PATH}
mkdir -p ${RENDER_PATH}
cp -r ${MANIFEST_PATH}/BaseConfig ${RENDER_PATH}/
cp -r ${MANIFEST_PATH}/${MODE_PATH} ${RENDER_PATH}/

# Rewrite every image reference, both the Deployment images and the browser images the
# Node starts as Jobs, which are listed in the ConfigMap
find ${RENDER_PATH} -type f -name '*.yaml' -exec \
  sed -i.bak -E "s#selenium/([a-z0-9-]+):[0-9][^\"'[:space:]]*#${NAMESPACE}/\1:${VERSION}#g" {} \;

if [ "${PLATFORMS}" != "linux/amd64" ]; then
  echo "Microsoft Edge is not built for ${PLATFORMS}, drop it from the browser configs"
  sed -i.bak '/standalone-edge/d' ${RENDER_PATH}/BaseConfig/configmap.yaml
fi

echo "Pin the browser Jobs to the images loaded in the cluster"
awk '{print} /\[kubernetes\]/{match($0, /^[[:space:]]*/); printf "%simage-pull-policy = \"IfNotPresent\"\n", substr($0, RSTART, RLENGTH)}' \
  ${RENDER_PATH}/BaseConfig/configmap.yaml >${RENDER_PATH}/BaseConfig/configmap.yaml.tmp
mv ${RENDER_PATH}/BaseConfig/configmap.yaml.tmp ${RENDER_PATH}/BaseConfig/configmap.yaml

find ${RENDER_PATH} -type f -name '*.bak' -delete
cat ${RENDER_PATH}/BaseConfig/configmap.yaml

echo "Prepare the host path backing the session assets PersistentVolume"
sudo -n mkdir -p ${ASSETS_HOST_PATH} 2>/dev/null || mkdir -p ${ASSETS_HOST_PATH}
sudo -n chmod -R 777 ${ASSETS_HOST_PATH} 2>/dev/null || chmod -R 777 ${ASSETS_HOST_PATH}

echo "Deploy the test site and the Dynamic Grid ${MODE}"
kubectl create ns ${SELENIUM_NAMESPACE} || true
kubectl apply -n ${SELENIUM_NAMESPACE} -f "${TEST_VALUES_PATH}/the-internet-deployment.yaml"
kubectl apply -n ${SELENIUM_NAMESPACE} -f ${RENDER_PATH}/BaseConfig

# The PersistentVolume is created by the kubelet owned by root, while the Grid runs as
# ${SEL_UID}. Session assets, managed downloads included, need it writable. Done through the
# claim so it works the same on any cluster, the host path is inside the node.
echo "Make the session assets volume writable by the Grid user"
cat <<EOF | kubectl apply -n ${SELENIUM_NAMESPACE} -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${ASSETS_PERMISSION_JOB}
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      securityContext:
        runAsUser: 0
      containers:
        - name: chmod
          image: busybox:1.37
          command: ["sh", "-c", "mkdir -p /assets && chmod -R 777 /assets"]
          volumeMounts:
            - name: session-assets
              mountPath: /assets
      volumes:
        - name: session-assets
          persistentVolumeClaim:
            claimName: selenium-assets
EOF
kubectl wait --for=condition=complete job/${ASSETS_PERMISSION_JOB} -n ${SELENIUM_NAMESPACE} --timeout ${WAIT_TIMEOUT}

kubectl apply -n ${SELENIUM_NAMESPACE} -f ${RENDER_PATH}/${MODE_PATH}

for deployment in ${DEPLOYMENTS}; do
  kubectl rollout status deployment/${deployment} -n ${SELENIUM_NAMESPACE} --timeout ${WAIT_TIMEOUT}
done
kubectl wait --for=condition=ready pod -l app=the-internet -n ${SELENIUM_NAMESPACE} --timeout ${WAIT_TIMEOUT}
kubectl get pods,svc,pvc -n ${SELENIUM_NAMESPACE}

echo "Forward the Grid endpoint, NodePort mapping differs between kind and minikube"
kubectl port-forward -n ${SELENIUM_NAMESPACE} svc/${GRID_SERVICE} ${GRID_LOCAL_PORT}:4444 &
PORT_FORWARD_PID=$!

GRID_READY="false"
for attempt in $(seq 1 ${GRID_READY_ATTEMPTS}); do
  if curl -sSf -u ${GRID_USERNAME}:${GRID_PASSWORD} "http://localhost:${GRID_LOCAL_PORT}/status" | grep -q '"ready": *true'; then
    GRID_READY="true"
    break
  fi
  sleep 5
done
if [ "${GRID_READY}" != "true" ]; then
  echo "Dynamic Grid ${MODE} is not ready after $((GRID_READY_ATTEMPTS * 5)) seconds"
  false
fi

echo "Run Tests"
export RUN_IN_DOCKER_COMPOSE=true
export SELENIUM_GRID_PROTOCOL="http"
export SELENIUM_GRID_HOST="localhost"
export SELENIUM_GRID_PORT=${GRID_LOCAL_PORT}
export SELENIUM_GRID_USERNAME=${GRID_USERNAME}
export SELENIUM_GRID_PASSWORD=${GRID_PASSWORD}
export SELENIUM_GRID_TEST_HEADLESS=${SELENIUM_GRID_TEST_HEADLESS:-"false"}
# The browser runs in its own Job Pod and downloads into it, while the Node serves the
# downloadable files from a Pod local directory, so managed downloads are not retrievable here
export SELENIUM_ENABLE_MANAGED_DOWNLOADS=${SELENIUM_ENABLE_MANAGED_DOWNLOADS:-"false"}
export TEST_DELAY_AFTER_TEST=${TEST_DELAY_AFTER_TEST:-"0"}
export BINDING_VERSION=${BINDING_VERSION}
export BASE_VERSION=${BASE_VERSION}

./tests/bootstrap.sh NodeChromium
./tests/bootstrap.sh NodeFirefox
if [ "${PLATFORMS}" = "linux/amd64" ]; then
  ./tests/bootstrap.sh NodeEdge
fi

echo "Browser Jobs created during the run"
kubectl get jobs -n ${SELENIUM_NAMESPACE} >>tests/tests/describe_dynamic_grid_${MODE}.txt || true

cleanup
