BUILD_DATE=$(date +'%Y%m%d')
VERSION="${VERSION:-4.1.3}"
NAMESPACE="${NAMESPACE:-seleniarm}"
AUTHORS=SeleniumHQ,sj26,jamesmortensen
ARCH=linux/arm64,linux/amd64,linux/arm/v7

echo "Register architectures via aptman/qus (QEMU User Static)...\n"

docker run --rm -it --privileged aptman/qus -- -r
docker run --rm -it --privileged aptman/qus -s -- -p

echo "Build multi-arch images and push to Docker Hub...\n"

cd ./Base && docker buildx build --push --platform $ARCH -t $NAMESPACE/base:$VERSION-$BUILD_DATE .
echo $PWD
cd ../Hub && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --push --platform $ARCH -t $NAMESPACE/hub:$VERSION-$BUILD_DATE .

cd ../NodeBase && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --push --platform $ARCH -t $NAMESPACE/node-base:$VERSION-$BUILD_DATE .
# && sed 's/chromium=.*/chromium=91.0.4472.124/' Dockerfile > Dockerfile \
cd ../NodeChromium && sh generate.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --push --platform $ARCH -t $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE .
cd ../NodeFirefox && sh generate-arm.sh $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && docker buildx build --push --platform $ARCH -t $NAMESPACE/node-firefox:$VERSION-$BUILD_DATE .

cd ../Standalone && sh generate.sh StandaloneChromium node-chromium $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && cd ../StandaloneChromium \
   && docker buildx build --push --platform $ARCH -t $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE .

cd ../Standalone && sh generate.sh StandaloneFirefox node-firefox $VERSION-$BUILD_DATE $NAMESPACE $AUTHORS \
   && cd ../StandaloneFirefox \
   && docker buildx build --push --platform $ARCH -t $NAMESPACE/standalone-firefox:$VERSION-$BUILD_DATE .

cd ..

echo "multi-arch: $ARCH"
echo "Build base, node-base, hub, node-chromium, node-firefox, standalone-chromium, and standalone-firefox...\n"
#echo "Tagging builds...\n"

# docker tag $NAMESPACE/base:$VERSION-$BUILD_DATE $NAMESPACE/base:latest
# docker tag $NAMESPACE/hub:$VERSION-$BUILD_DATE $NAMESPACE/hub:latest
# docker tag $NAMESPACE/node-base:$VERSION-$BUILD_DATE $NAMESPACE/node-base:latest
# docker tag $NAMESPACE/node-chromium:$VERSION-$BUILD_DATE $NAMESPACE/node-chromium:latest
# docker tag $NAMESPACE/standalone-chromium:$VERSION-$BUILD_DATE $NAMESPACE/standalone-chromium:latest

