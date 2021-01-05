#!/usr/bin/env bash
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python -m pip install selenium===3.141.0 \
                      docker===4.4.1 \
                      | grep -v 'Requirement already satisfied'

python test.py $1
ret_code=$?

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

exit $ret_code
