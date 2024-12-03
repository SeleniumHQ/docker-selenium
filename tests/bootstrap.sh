#!/usr/bin/env bash
set -o xtrace

MATRIX_TESTS=${MATRIX_TESTS:-"default"}

cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

if [[ "${BASE_VERSION}" == *-SNAPSHOT ]]; then
  latest_version="$(curl -s https://test.pypi.org/pypi/selenium/json | jq -r '.releases | to_entries | sort_by(.value[0].upload_time) | .[-1].key')"
  python3 -m pip install --index-url https://test.pypi.org/simple/ selenium==${latest_version} --extra-index-url https://pypi.org/simple/ --upgrade --force-reinstall --break-system-packages | grep -v 'Requirement already satisfied'
else
  python3 -m pip install selenium==${BINDING_VERSION} | grep -v 'Requirement already satisfied'
fi

python3 -m pip install -r requirements.txt | grep -v 'Requirement already satisfied'

if [ "$1" = "AutoscalingTestsScaleUp" ]; then
  python3 -m unittest AutoscalingTests.test_scale_up
  ret_code=$?
elif [ "$1" = "AutoScalingTestsScaleChaos" ]; then
  python3 -m unittest AutoscalingTests.test_scale_chaos
  ret_code=$?
else
  python3 test.py $1
  ret_code=$?
fi

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

sleep 5

exit $ret_code
