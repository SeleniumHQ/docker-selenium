ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/node-base:${VERSION}
LABEL authors=${AUTHORS}

USER root

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable
#       google-chrome-beta
#       google-chrome-unstable
#============================================
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chrome Launch Script Wrapper
#=================================
COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN /opt/bin/wrap_chrome_binary

USER 1200

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG CHROME_DRIVER_VERSION
RUN if [ ! -z "$CHROME_DRIVER_VERSION" ]; \
  then CHROME_DRIVER_URL=https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/$CHROME_DRIVER_VERSION/linux64/chromedriver-linux64.zip ; \
  else echo "Geting ChromeDriver binary from https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json" \
    && CFT_URL=https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json \
    && CFT_CHANNEL="Stable" \
    && if [ "$CHROME_VERSION" = "google-chrome-beta" ]; then CFT_CHANNEL="Beta" ; fi \
    && if [ "$CHROME_VERSION" = "google-chrome-unstable" ]; then CFT_CHANNEL="Dev" ; fi \
    && echo $CFT_CHANNEL \
    && CTF_VALUES=$(curl -sSL $CFT_URL | jq -r --arg CFT_CHANNEL "$CFT_CHANNEL" '.channels[] | select (.channel==$CFT_CHANNEL)') \
    && CHROME_DRIVER_VERSION=$(echo $CTF_VALUES | jq -r '.version' ) \
    && CHROME_DRIVER_URL=$(echo $CTF_VALUES | jq -r '.downloads.chromedriver[] | select(.platform=="linux64") | .url' ) ; \
  fi \
  && echo "Using ChromeDriver from: "$CHROME_DRIVER_URL \
  && echo "Using ChromeDriver version: "$CHROME_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip $CHROME_DRIVER_URL \
  && rm -rf /opt/selenium/chromedriver \
  && sudo unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && sudo mv /opt/selenium/chromedriver-linux64/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && sudo chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && sudo ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#============================================
# Dumping Browser name and version for config
#============================================
RUN echo "chrome" > /opt/selenium/browser_name
