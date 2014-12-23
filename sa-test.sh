#!/bin/sh

echo Building test container image
docker build -t selenium/test:local ./Test

function test_standalone {
  BROWSER=$1
  echo Starting $BROWSER standalone container

  SA=$(docker run -d selenium/standalone-$BROWSER:2.44.0)
  SA_NAME=$(docker inspect -f '{{ .Name  }}' $SA | sed s:/::)
  TEST_CMD="node smoke-$BROWSER.js"

  echo Running test container...
  docker run --rm -it --link $SA_NAME:hub -e "TEST_CMD=$TEST_CMD" selenium/test:local
  STATUS=$?

  echo Tearing down Selenium $BROWSER standalone container

  docker stop $SA_NAME
  docker rm $SA_NAME

  if [ ! $STATUS == 0 ]; then
    echo Failed
    exit 1
  fi
}

test_standalone firefox
test_standalone chrome
