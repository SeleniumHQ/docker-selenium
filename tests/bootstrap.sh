#!/usr/bin/env bash
cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

if [[ "${BASE_VERSION}" == *-SNAPSHOT ]]; then
  latest_version="$(curl -s https://test.pypi.org/pypi/selenium/json | jq -r '.releases | keys | .[]' | sort -V | tail -n 1)"
  python3 -m pip install --index-url https://test.pypi.org/simple/ selenium==${latest_version} --extra-index-url https://pypi.org/simple/ --upgrade --force-reinstall --break-system-packages | grep -v 'Requirement already satisfied'
else
  python3 -m pip install selenium==${BINDING_VERSION} | grep -v 'Requirement already satisfied'
fi

python3 -m pip install docker requests chardet | grep -v 'Requirement already satisfied'

python3 test.py $1
ret_code=$?

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi

sleep 5

exit $ret_code
