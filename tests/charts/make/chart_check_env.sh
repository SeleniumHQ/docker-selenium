#!/bin/bash

REQUIRED_VERSION="24.0.9"
DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
version_greater_equal() {
    [ "$1" = "$2" ] && return 0
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=0; i<${#ver1[@]}; i++)); do
        [ -z "${ver2[i]}" ] && ver2[i]=0
        ((10#${ver1[i]} > 10#${ver2[i]})) && return 0
        ((10#${ver1[i]} < 10#${ver2[i]})) && return 1
    done
    return 0
}
if version_greater_equal "$DOCKER_VERSION" "$REQUIRED_VERSION"; then
    echo "Docker engine version is $DOCKER_VERSION"
    EXIT_CODE=0
else
    echo "Docker engine version is $DOCKER_VERSION, which does not meet the requirement."
    EXIT_CODE=1
fi

DOCKER_CONFIG_FILE="/etc/docker/daemon.json"
if [ ! -f "$DOCKER_CONFIG_FILE" ]; then
  echo "Docker configuration file not found at $DOCKER_CONFIG_FILE"
  EXIT_CODE=1
fi
if cat "$DOCKER_CONFIG_FILE" | grep -q containerd; then
  echo "The containerd feature is enabled in Docker engine. $(cat $DOCKER_CONFIG_FILE)"
else
  echo "The containerd feature is not enabled in Docker engine. $(cat $DOCKER_CONFIG_FILE)"
  EXIT_CODE=1
fi

echo "==============================="
if [ "$EXIT_CODE" -eq 1 ]; then
  echo "Check failed."
  echo "Please run the following command setup development environment: make setup_dev_env"
  exit $EXIT_CODE
else
  echo "All checks passed."
  exit 0
fi
