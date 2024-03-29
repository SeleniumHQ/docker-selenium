#!/usr/bin/env bash
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python -m pip install selenium==4.19.0 \
                      docker===7.0.0 \
                      | grep -v 'Requirement already satisfied'

if [ "${SELENIUM_GRID_PROTOCOL}" = "https" ]; then
  export REQUESTS_CA_BUNDLE="${CHART_CERT_PATH}"
fi

python test.py $1
ret_code=$?

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

exit $ret_code
