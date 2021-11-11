# This script tags all of the latest images with seleniarm, for deploying to Docker Hub.

BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.0.0
LOCAL_NAMESPACE=local-seleniarm
NAMESPACE=seleniarm

docker tag $LOCAL_NAMESPACE/base:latest $NAMESPACE/base:latest 
docker tag $LOCAL_NAMESPACE/base:$VERSION-$BUILD_DATE $NAMESPACE/base:$VERSION-$BUILD_DATE 

docker tag $LOCAL_NAMESPACE/hub:latest $NAMESPACE/hub:latest 
docker tag $LOCAL_NAMESPACE/hub:$VERSION-$BUILD_DATE $NAMESPACE/hub:$VERSION-$BUILD_DATE 

docker tag $LOCAL_NAMESPACE/node-base:latest $NAMESPACE/node-base:latest 
docker tag $LOCAL_NAMESPACE/node-base:$VERSION-$BUILD_DATE $NAMESPACE/node-base:$VERSION-$BUILD_DATE 

docker tag $LOCAL_NAMESPACE/node-chromium:latest $NAMESPACE/node-chromium:latest 
docker tag $LOCAL_NAMESPACE/node-chromium:$VERSION-$BUILD_DATE $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE 

docker tag $LOCAL_NAMESPACE/standalone-chromium:latest $NAMESPACE/standalone-chromium:latest 
docker tag $LOCAL_NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE 

docker tag $LOCAL_NAMESPACE/node-firefox:latest $NAMESPACE/node-firefox:latest 
docker tag $LOCAL_NAMESPACE/node-firefox:$VERSION-$BUILD_DATE $NAMESPACE/node-firefox:$VERSION-$BUILD_DATE 

docker tag $LOCAL_NAMESPACE/standalone-firefox:latest $NAMESPACE/standalone-firefox:latest 
docker tag $LOCAL_NAMESPACE/standalone-firefox:$VERSION-$BUILD_DATE $NAMESPACE/standalone-firefox:$VERSION-$BUILD_DATE 
