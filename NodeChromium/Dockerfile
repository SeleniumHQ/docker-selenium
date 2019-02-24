# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/node-base:3.141.59-iron
LABEL authors=SeleniumHQ

USER root

#=========
# Chrome
#=========

RUN apt-get update
RUN apt-get -y install chromium-browser \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#==================
# Chrome webdriver
#==================

RUN apt-get update
RUN apt-get -y install chromium-chromedriver \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN ln -s /usr/lib/chromium-browser/chromedriver /usr/bin/chromedriver

#========================
# Selenium Configuration
#========================
# As integer, maps to "maxInstances"
ENV NODE_MAX_INSTANCES 1
# As integer, maps to "maxSession"
ENV NODE_MAX_SESSION 1
# As integer, maps to "port"
ENV NODE_PORT 5555
# In milliseconds, maps to "registerCycle"
ENV NODE_REGISTER_CYCLE 5000
# In milliseconds, maps to "nodePolling"
ENV NODE_POLLING 5000
# In milliseconds, maps to "unregisterIfStillDownAfter"
ENV NODE_UNREGISTER_IF_STILL_DOWN_AFTER 60000
# As integer, maps to "downPollingLimit"
ENV NODE_DOWN_POLLING_LIMIT 2
# As string, maps to "applicationName"
ENV NODE_APPLICATION_NAME ""

COPY generate_config /opt/selenium/generate_config
RUN chmod +x /opt/selenium/generate_config

#=================================
# Chrome Launch Script Modification
#=================================
COPY chrome_launcher.sh /opt/google/chrome/google-chrome
RUN chmod +x /opt/google/chrome/google-chrome

RUN chown -R seluser:seluser /opt/selenium

# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

USER seluser
