#!/usr/bin/env bash
cd tests

if [ "${TRAVIS:-false}" = "false" ]; then
  pip install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi


python -m pip install selenium===3.14.1 \
                      docker===3.5.0 \
                      | grep -v 'Requirement already satisfied'

python test.py $1 $2
ret_code=$?

if [ "${TRAVIS:-false}" = "false" ]; then
  deactivate
fi

exit $ret_code
