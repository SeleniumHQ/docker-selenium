#!/usr/bin/env bash

echo Building test container image
docker build -t selenium/test:local ./Test

function test_standalone {
  BROWSER=$1
  echo Starting $BROWSER standalone container

  SA=$(docker run -d selenium/standalone-$BROWSER:2.45.0)
  SA_NAME=$(docker inspect -f '{{ .Name  }}' $SA | sed s:/::)
  TEST_CMD="node smoke-$BROWSER.js"

  echo Running test container...
  docker run -it --link $SA_NAME:hub -e "TEST_CMD=$TEST_CMD" selenium/test:local
  STATUS=$?
  TEST_CONTAINER=$(docker ps -aq | head -1)

  if [ ! $STATUS == 0 ]; then
    echo Failed
    exit 1
  fi

  if [ ! "$CIRCLECI" ==  "true" ]; then
    echo Tearing down Selenium $BROWSER standalone container
    docker stop $SA_NAME
    docker rm $SA_NAME
    echo Removing the test container
    docker rm $TEST_CONTAINER
  fi
}

test_standalone firefox
test_standalone chrome
