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
  charts/selenium-grid > ./tests/tests/output_deployment.yaml

python tests/charts/templates/test.py "./tests/tests/output_deployment.yaml"
ret_code=$?

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

exit $ret_code
