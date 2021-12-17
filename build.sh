BUILD_DATE=$(date +'%Y%m%d')
VERSION=4.1.0
CHROMIUM=93.0.4577.82  # Not yet used at this time. Edit in NodeChromium/Dockerfile.txt
NAMESPACE=local-seleniarm
AUTHORS=SeleniumHQ,sj26,jamesmortensen

cd ./Base && docker buildx build --platform linux/arm64 -t $NAMESPACE/base:$VERSION-$BUILD_DATE .
echo $PWD
cd ../Hub && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform linux/arm64 -t $NAMESPACE/hub:$VERSION-$BUILD_DATE .

cd ../NodeBase && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform linux/arm64 -t $NAMESPACE/node-base:$VERSION-$BUILD_DATE .
# && sed 's/chromium=.*/chromium=91.0.4472.124/' Dockerfile > Dockerfile \
cd ../NodeChromium && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --platform linux/arm64 -t $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE .

cd ../Standalone && sh generate.sh StandaloneChromium node-chromium $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && cd ../StandaloneChromium \
   && docker buildx build --platform linux/arm64 -t $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE .

echo "Build node-hub, node-chromium, and standalone-chromium...\n"
echo "Tagging builds...\n"

docker tag $NAMESPACE/base:$VERSION-$BUILD_DATE $NAMESPACE/base:latest
docker tag $NAMESPACE/hub:$VERSION-$BUILD_DATE $NAMESPACE/hub:latest
docker tag $NAMESPACE/node-base:$VERSION-$BUILD_DATE $NAMESPACE/node-base:latest
docker tag $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE $NAMESPACE/node-chromium:latest
docker tag $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE $NAMESPACE/standalone-chromium:latest

