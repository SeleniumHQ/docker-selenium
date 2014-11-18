#!/bin/bash

echo Building test container image
docker build -t selenium/test:local ./Test

echo Starting Selenium Container
HUB=$(docker run -d selenium/hub:2.44.0)
HUB_NAME=$(docker inspect -f '{{ .Name  }}' $HUB | sed s:/::)
sleep 2

echo Hub Name $HUB_NAME

NODE_CHROME=$(docker run -d --link $HUB_NAME:hub selenium/node-chrome:2.44.0)
NODE_FIREFOX=$(docker run -d --link $HUB_NAME:hub selenium/node-firefox:2.44.0)

trap "echo Tearing down Selenium Chrome Node container; docker stop $NODE_CHROME; docker rm $NODE_CHROME; echo Tearing down Selenium Firefox Node container; docker stop $NODE_FIREFOX; docker rm $NODE_FIREFOX; echo Tearing down Selenium Hub container; docker stop $HUB; docker rm $HUB; echo Done" EXIT

docker logs -f $HUB &
docker logs -f $NODE_CHROME &
docker logs -f $NODE_FIREFOX &
sleep 2

echo Running test container...
docker run --rm -it --link $HUB_NAME:hub selenium/test:local
