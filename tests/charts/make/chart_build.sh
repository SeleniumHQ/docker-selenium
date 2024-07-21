#!/bin/bash
set -x

SET_VERSION=${SET_VERSION:-"true"}
CHART_PATH=${CHART_PATH:-"charts/selenium-grid"}
# Function to be executed on command failure
on_failure() {
    local exit_status=$?
    echo "There is step failed with exit status $exit_status"
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
else
  export PATH=$PATH:/home/$USER/.local/bin
  pip3 install -U yamale yamllint
fi

python3 -m pip install yamale==4.0.4 \
                      yamllint==1.33.0 \
                      | grep -v 'Requirement already satisfied' || true

cd ..
rm -rf ${CHART_PATH}/Chart.lock
ct lint --all --config tests/charts/config/ct.yaml
# Helm dependencies build and lint is done by `ct lint` command
rm -rf ${CHART_PATH}/../*.tgz

if [ "${SET_VERSION}" = "true" ]; then
  ADD_VERSION="--version ${VERSION}"
else
  ADD_VERSION=""
fi

helm package ${CHART_PATH} ${ADD_VERSION} --destination ${CHART_PATH}/..

readlink -f ${CHART_PATH}/../*.tgz > /tmp/selenium_chart_version
cat /tmp/selenium_chart_version

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi
