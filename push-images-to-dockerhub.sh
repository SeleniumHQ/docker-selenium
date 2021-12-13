BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.0.0
NAMESPACE=seleniarm


docker push seleniarm/base:4.0.0-$BUILD_DATE
docker push seleniarm/hub:4.0.0-$BUILD_DATE
docker push seleniarm/node-base:4.0.0-$BUILD_DATE
docker push seleniarm/node-chromium:4.0.0-$BUILD_DATE
docker push seleniarm/node-firefox:4.0.0-$BUILD_DATE
docker push seleniarm/standalone-chromium:4.0.0-$BUILD_DATE
docker push seleniarm/standalone-firefox:4.0.0-$BUILD_DATE

docker push seleniarm/base:latest
docker push seleniarm/hub:latest
docker push seleniarm/node-base:latest
docker push seleniarm/node-chromium:latest
docker push seleniarm/node-firefox:latest
docker push seleniarm/standalone-chromium:latest
docker push seleniarm/standalone-firefox:latest

