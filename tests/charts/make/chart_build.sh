#!/bin/bash

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
fi

python -m pip install yamale==4.0.4 \
                      yamllint==1.33.0 \
                      | grep -v 'Requirement already satisfied'

cd ..
rm -rf ${CHART_PATH}/Chart.lock
ct lint --all --config tests/charts/config/ct.yaml
# Helm dependencies build and lint is done by `ct lint` command
rm -rf ${CHART_PATH}/../*.tgz
helm package ${CHART_PATH} --version ${VERSION} --destination ${CHART_PATH}/..

readlink -f ${CHART_PATH}/../*.tgz > /tmp/selenium_chart_version
cat /tmp/selenium_chart_version

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi
