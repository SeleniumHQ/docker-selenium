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
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/trusted.gpg.d/google.gpg >/dev/null \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chrome Launch Script Wrapper
#=================================
COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN /opt/bin/wrap_chrome_binary

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG CHROME_DRIVER_VERSION
RUN if [ ! -z "$CHROME_DRIVER_VERSION" ]; \
  then CHROME_DRIVER_URL=https://storage.googleapis.com/chrome-for-testing-public/$CHROME_DRIVER_VERSION/linux64/chromedriver-linux64.zip ; \
  else CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/") \
    && echo "Geting ChromeDriver latest version from https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR_VERSION}" \
    && CHROME_DRIVER_VERSION=$(wget -qO- https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR_VERSION} | sed 's/\r$//') \
    && CHROME_DRIVER_URL=https://storage.googleapis.com/chrome-for-testing-public/$CHROME_DRIVER_VERSION/linux64/chromedriver-linux64.zip ; \
  fi \
  && echo "Using ChromeDriver from: "$CHROME_DRIVER_URL \
  && echo "Using ChromeDriver version: "$CHROME_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip $CHROME_DRIVER_URL \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver-linux64/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#============================================
# Chrome cleanup script and supervisord file
#============================================
ENV SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP false
ENV SE_BROWSER_LEFTOVERS_INTERVAL_SECS 3600
ENV SE_BROWSER_LEFTOVERS_PROCESSES_SECS 1200
ENV SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS 1
COPY chrome-cleanup.sh /opt/bin/chrome-cleanup.sh
COPY chrome-cleanup.conf /etc/supervisor/conf.d/chrome-cleanup.conf

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN echo "chrome" > /opt/selenium/browser_name
RUN google-chrome --version | awk '{print $3}' | cut -d'.' -f1,2 > /opt/selenium/browser_version
RUN echo "\"goog:chromeOptions\": {\"binary\": \"/usr/bin/google-chrome\"}" > /opt/selenium/browser_binary_location

ENV SE_OTEL_SERVICE_NAME "selenium-node-chrome"
