#!/usr/bin/env bash
mkdir -p tests/tests
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python3 -m pip install pyyaml==6.0.1 \
                      | grep -v 'Requirement already satisfied'

cd ..

helm package charts/selenium-grid --version 1.0.0-SNAPSHOT -d tests/tests

RELEASE_NAME="selenium"

helm template ${RELEASE_NAME} --values tests/charts/templates/render/dummy.yaml \
  --values charts/selenium-grid/cross-browsers-values.yaml \
  --set-file 'nodeConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'recorderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'uploaderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  tests/tests/selenium-grid-1.0.0-SNAPSHOT.tgz > ./tests/tests/dummy_template_manifests.yaml

python3 tests/charts/templates/test.py "./tests/tests/dummy_template_manifests.yaml" ${RELEASE_NAME}
if [ $? -ne 0 ]; then
  echo "Failed to validate the chart"
  exit 1
fi

rm -rf tests/charts/umbrella-charts/Chart.lock tests/charts/umbrella-charts/charts
helm dependency update tests/charts/umbrella-charts
helm dependency build tests/charts/umbrella-charts
helm package tests/charts/umbrella-charts --version 1.0.0-SNAPSHOT -d tests/tests

RELEASE_NAME="test"

helm template ${RELEASE_NAME} --values tests/charts/templates/render/dummy_solution.yaml \
  --values charts/selenium-grid/cross-browsers-values.yaml \
  --set-file 'selenium-grid.nodeConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'selenium-grid.recorderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'selenium-grid.uploaderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  tests/tests/umbrella-charts-1.0.0-SNAPSHOT.tgz > ./tests/tests/dummy_solution_template_manifests.yaml

python3 tests/charts/templates/test.py "./tests/tests/dummy_solution_template_manifests.yaml" ${RELEASE_NAME}
if [ $? -ne 0 ]; then
  echo "Failed to validate the umbrella chart"
  exit 1
fi

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi
