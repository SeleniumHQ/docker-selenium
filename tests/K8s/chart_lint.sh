#!/bin/bash
# Function to be executed on command failure
on_failure() {
    echo "There is step failed with exit status $?"
    exit $?
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
ct lint --all --config tests/K8s/chart-testing.yaml

if [ "${CI:-false}" = "false" ]; then
  deactivate
fi
