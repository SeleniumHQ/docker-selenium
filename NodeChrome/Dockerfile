ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/node-base:${VERSION}
LABEL authors=${AUTHORS}

USER root

RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install libatk1.0-0 libatk-bridge2.0-0 \
    libxkbcommon-x11-0 libgbm1 libpango-1.0-0 \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  Support these inputs (following https://github.com/GoogleChromeLabs/chrome-for-testing):
#       LATEST_RELEASE_STABLE
#       LATEST_RELEASE_BETA
#       LATEST_RELEASE_DEV
#       LATEST_RELEASE_CANARY
#       121 (specific major version)
#       119.0.6045.105 (specific full version)
#============================================
ARG DOWNLOAD_HOST="https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing"
ARG VERSION_HOST="https://googlechromelabs.github.io/chrome-for-testing"
ARG CHROME_VERSION="LATEST_RELEASE_STABLE"
ARG CHROME_PLATFORM="linux64"
RUN if [ ! -z "$CHROME_VERSION" ]; \
  then GET_VERSION_URL=$VERSION_HOST/$CHROME_VERSION \
    && if [ $(curl -I -s -o /dev/null -w "%{http_code}" $GET_VERSION_URL) -eq 200 ]; \
      then echo "Getting Chrome version from "$GET_VERSION_URL \
      && CHROME_VERSION=$(wget -qO- $VERSION_HOST"/"$CHROME_VERSION | sed 's/\r$//') ; \
    fi \
  else echo "Getting Chrome version "$CHROME_DRIVER_VERSION ; \
  fi \
  && CHROME_URL=$DOWNLOAD_HOST/$CHROME_VERSION/$CHROME_PLATFORM/chrome-$CHROME_PLATFORM.zip \
  && if [ $(curl -I -s -o /dev/null -w "%{http_code}" $CHROME_URL) -ne 200 ]; \
    then CHROME_MAJOR_VERSION=$(echo $CHROME_VERSION | sed -E "s/([0-9]+).*/\1/") \
    && echo "Getting Chrome latest major version from "$VERSION_HOST"/LATEST_RELEASE_"$CHROME_MAJOR_VERSION \
    && CHROME_VERSION=$(wget -qO- $VERSION_HOST/LATEST_RELEASE_${CHROME_MAJOR_VERSION} | sed 's/\r$//') \
    && CHROME_URL=$DOWNLOAD_HOST/$CHROME_VERSION/$CHROME_PLATFORM/chrome-$CHROME_PLATFORM.zip ; \
  fi \
  && echo "Using Chrome from: "$CHROME_URL \
  && wget --no-verbose -O /tmp/chrome-$CHROME_PLATFORM.zip $CHROME_URL \
  && rm -rf /opt/google/chrome \
  && unzip /tmp/chrome-$CHROME_PLATFORM.zip -d /opt/google \
  && mv /opt/google/chrome-$CHROME_PLATFORM /opt/google/chrome \
  && rm /tmp/chrome-$CHROME_PLATFORM.zip \
  && mv /opt/google/chrome/chrome-wrapper /opt/google/chrome/google-chrome \
  && chmod +x /opt/google/chrome/google-chrome \
  && ln -fs /opt/google/chrome/google-chrome /usr/bin/google-chrome

#=================================
# Chrome Launch Script Wrapper
#=================================
COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN /opt/bin/wrap_chrome_binary

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version (following browser version) will be used by default
#============================================
ARG CHROME_DRIVER_VERSION=$CHROME_VERSION
RUN if [ ! -z "$CHROME_DRIVER_VERSION" ]; \
  then GET_VERSION_URL=$VERSION_HOST/$CHROME_DRIVER_VERSION \
    && if [ $(curl -I -s -o /dev/null -w "%{http_code}" $GET_VERSION_URL) -eq 200 ]; \
      then echo "Getting ChromeDriver version from "$GET_VERSION_URL \
      && CHROME_DRIVER_VERSION=$(wget -qO- $VERSION_HOST"/"$CHROME_DRIVER_VERSION | sed 's/\r$//') ; \
    fi \
  else CHROME_DRIVER_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+(\.[0-9]+)+).*/\1/") \
    && echo "Getting ChromeDriver same as browser version "$CHROME_DRIVER_VERSION ; \
  fi \
  && CHROME_DRIVER_URL=$DOWNLOAD_HOST/$CHROME_DRIVER_VERSION/$CHROME_PLATFORM/chromedriver-$CHROME_PLATFORM.zip \
  && if [ $(curl -I -s -o /dev/null -w "%{http_code}" $CHROME_DRIVER_URL) -ne 200 ]; \
    then CHROME_MAJOR_VERSION=$(echo $CHROME_DRIVER_VERSION | sed -E "s/([0-9]+).*/\1/") \
    && echo "Getting ChromeDriver latest major version from "$VERSION_HOST"/LATEST_RELEASE_"$CHROME_MAJOR_VERSION \
    && CHROME_DRIVER_VERSION=$(wget -qO- $VERSION_HOST/LATEST_RELEASE_${CHROME_MAJOR_VERSION} | sed 's/\r$//') \
    && CHROME_DRIVER_URL=$DOWNLOAD_HOST/$CHROME_DRIVER_VERSION/$CHROME_PLATFORM/chromedriver-$CHROME_PLATFORM.zip ; \
  fi \
  && echo "Using ChromeDriver from: "$CHROME_DRIVER_URL \
  && echo "Using ChromeDriver version: "$CHROME_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_$CHROME_PLATFORM.zip $CHROME_DRIVER_URL \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_$CHROME_PLATFORM.zip -d /opt/selenium \
  && rm /tmp/chromedriver_$CHROME_PLATFORM.zip \
  && mv /opt/selenium/chromedriver-$CHROME_PLATFORM/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver
ENV SE_DRIVER_OPTS="-Dwebdriver.chrome.driver="${CHROME_DRIVER_PATH_PROPERTY:-"/usr/bin/chromedriver"}" "$SE_DRIVER_OPTS

USER 1200

#============================================
# Dumping Browser information for config
#============================================
RUN echo "chrome" > /opt/selenium/browser_name
RUN google-chrome --version | awk '{print $5}' > /opt/selenium/browser_version
RUN echo "\"goog:chromeOptions\": {\"binary\": \"/usr/bin/google-chrome\"}" > /opt/selenium/browser_binary_location
