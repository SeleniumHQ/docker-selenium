#!/bin/bash
# Function to be executed on command failure
on_failure() {
    local exit_status=$?
    echo "There is step failed with exit status $exit_status"
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

cd tests || true

if [ "${CI:-false}" = "false" ]; then
  pip3 install virtualenv | grep -v 'Requirement already satisfied'
  virtualenv docker-selenium-tests
  source docker-selenium-tests/bin/activate
fi

python -m pip install yamale==4.0.4 \
                      yamllint==1.33.0 \
                      | grep -v 'Requirement already satisfied'

cd ..
rm -rf ./charts/**/Chart.lock
ct lint --all --config tests/charts/config/ct.yaml

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi
