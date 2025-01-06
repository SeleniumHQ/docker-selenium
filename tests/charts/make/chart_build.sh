#!/bin/bash
set -o xtrace

SET_VERSION=${SET_VERSION:-"true"}
CHART_PATH=${CHART_PATH:-"charts/selenium-grid"}

cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
else
  export PATH=$PATH:/home/$USER/.local/bin
fi

python3 -m pip install -r requirements.txt | grep -v 'Requirement already satisfied'

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
