#!/usr/bin/env bash
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python3 -m pip install selenium==${BINDING_VERSION} \
                      docker===7.0.0 \
                      requests===2.31.0 \
                      chardet \
                      | grep -v 'Requirement already satisfied'

if [ "${SELENIUM_GRID_PROTOCOL}" = "https" ]; then
  export REQUESTS_CA_BUNDLE="${CHART_CERT_PATH}"
fi

python3 test.py $1
ret_code=$?

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

sleep 5

exit $ret_code
