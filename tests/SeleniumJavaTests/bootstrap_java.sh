#!/bin/bash

# Usage: ./bootstrap_java.sh [BROWSER] [IMAGE_NAME] [GRID_URL]
BROWSER="${1:-"chrome"}"
IMAGE_NAME="${2:-"standalone-chrome"}"
GRID_URL="${3:-"http://localhost:4444"}"
NAMESPACE="${NAMESPACE:-"selenium"}"
VERSION="${VERSION:-"latest"}"

function cleanup {
  echo "Stopping the Selenium Grid container..."
  docker rm -f standalone || true
  docker rm -f the-internet || true
  docker network rm standalone || true
  exit $exit_code
}

trap cleanup EXIT

# Change to the test directory relative to the project root
cd "$(dirname "$0")"

docker network create standalone
docker run --rm --name the-internet -d --network standalone "ndviet/the-internet:latest"
docker run --rm --name standalone -d --network standalone -p 4444:4444 "${NAMESPACE}/${IMAGE_NAME}:${VERSION}"

until curl -s "${GRID_URL}/status" | grep -q 'Selenium Grid ready'; do
  echo "Waiting for Selenium Grid to be ready..."
  sleep 2
done
echo "Selenium Grid is ready."

echo "Running tests with Selenium Grid at ${GRID_URL}"

export GRID_URL="${GRID_URL}"
export BROWSER="${BROWSER}"
export TEST_SITE="the-internet:5000"
./gradlew clean test
exit_code=$?