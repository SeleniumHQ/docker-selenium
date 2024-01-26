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
  --set-file 'nodeConfigMap.extraScripts.nodePreStop\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'recorderConfigMap.extraScripts.video\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'recorderConfigMap.extraScripts.graphQLRecordVideo\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'recorderConfigMap.extraScripts.newInsertScript\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'uploaderConfigMap.extraScripts.entry_point\.sh=tests/charts/templates/render/dummy_external.sh' \
  --set-file 'uploaderConfigMap.secretFiles.config\.conf=tests/charts/templates/render/dummy_external.sh' \
  charts/selenium-grid > ./tests/tests/dummy_template_manifests.yaml

python tests/charts/templates/test.py "./tests/tests/dummy_template_manifests.yaml" dummy
ret_code=$?

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

exit $ret_code
