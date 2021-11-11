# This script retags all of the latest images with the current date tag, in case we want to rebuild images
# without rebuilding from scratch.

BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.0.0
NAMESPACE=local-seleniarm

docker tag $NAMESPACE/base:latest $NAMESPACE/base:$VERSION-$BUILD_DATE 
docker tag $NAMESPACE/hub:latest $NAMESPACE/hub:$VERSION-$BUILD_DATE 
docker tag $NAMESPACE/node-base:latest $NAMESPACE/node-base:$VERSION-$BUILD_DATE 
docker tag $NAMESPACE/node-chromium:latest $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE 
docker tag $NAMESPACE/standalone-chromium:latest $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE 

docker tag $NAMESPACE/node-firefox:latest $NAMESPACE/node-firefox:$VERSION-$BUILD_DATE 
docker tag $NAMESPACE/standalone-firefox:latest $NAMESPACE/standalone-firefox:$VERSION-$BUILD_DATE 
