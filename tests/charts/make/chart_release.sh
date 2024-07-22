#!/bin/bash
set -x

NAMESPACE=${NAMESPACE:-"selenium"}
# Function to be executed on command failure
on_failure() {
    local exit_status=$?
    echo "There is step failed with exit status $exit_status"
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

CHART_PACKAGE_PATH=$(cat /tmp/selenium_chart_version)
if [ -z "${CHART_PACKAGE_PATH}" ] || [ ! -f "${CHART_PACKAGE_PATH}" ]; then
    echo "Chart package path is empty. Please trigger chart_build.sh before this script."
    exit 1
fi

echo "Pushing chart package to the registry"
helm push ${CHART_PACKAGE_PATH} oci://registry-1.docker.io/${NAMESPACE}
