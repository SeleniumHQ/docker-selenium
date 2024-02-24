#!/usr/bin/env bash
mkdir -p tests/tests
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python -m pip install pyyaml==6.0.1 \
                      | grep -v 'Requirement already satisfied'

cd ..

helm template dummy --values tests/charts/templates/render/dummy.yaml \
  --set-file 'nodeConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'recorderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'uploaderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  charts/selenium-grid > ./tests/tests/dummy_template_manifests.yaml

python tests/charts/templates/test.py "./tests/tests/dummy_template_manifests.yaml" dummy
if [ $? -ne 0 ]; then
  echo "Failed to validate the chart"
  exit 1
fi

helm dependency update tests/charts/umbrella-charts
helm dependency build tests/charts/umbrella-charts

helm template dummy --values tests/charts/templates/render/dummy_solution.yaml \
  --set-file 'selenium-grid.nodeConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'selenium-grid.recorderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'selenium-grid.uploaderConfigMap.extraScripts.setFromCommand\.sh=tests/charts/templates/render/dummy_external.sh' \
  tests/charts/umbrella-charts > ./tests/tests/dummy_solution_template_manifests.yaml

python tests/charts/templates/test.py "./tests/tests/dummy_solution_template_manifests.yaml" dummy
if [ $? -ne 0 ]; then
  echo "Failed to validate the umbrella chart"
  exit 1
fi

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

exit $ret_code
