#!/usr/bin/env bash
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python -m pip install selenium==4.15.0 \
                      docker===6.1.3 \
                      | grep -v 'Requirement already satisfied'

python $1 $2
ret_code=$?

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

exit $ret_code
