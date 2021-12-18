BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.1.0
NAMESPACE=seleniarm


docker push seleniarm/base:$VERSION-$BUILD_DATE
docker push seleniarm/hub:$VERSION-$BUILD_DATE
docker push seleniarm/node-base:$VERSION-$BUILD_DATE
docker push seleniarm/node-chromium:$VERSION-$BUILD_DATE
docker push seleniarm/node-firefox:$VERSION-$BUILD_DATE
docker push seleniarm/standalone-chromium:$VERSION-$BUILD_DATE
docker push seleniarm/standalone-firefox:$VERSION-$BUILD_DATE

docker push seleniarm/base:latest
docker push seleniarm/hub:latest
docker push seleniarm/node-base:latest
docker push seleniarm/node-chromium:latest
docker push seleniarm/node-firefox:latest
docker push seleniarm/standalone-chromium:latest
docker push seleniarm/standalone-firefox:latest

