ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/node-base:${VERSION}
LABEL authors=${AUTHORS}

USER root

#ENV LANGUAGE=en_US.UTF-8
#ENV LC_ALL=en_US.UTF-8
#ENV LANG=en_US.UTF-8

# Deal with the usr merge issues in Debian
#RUN apt install usrmerge

# Install Chromium 
# RUN echo "deb http://http.us.debian.org/debian/ stable non-free contrib main" >> /etc/apt/sources.list \
RUN echo "deb http://deb.debian.org/debian/ sid main" >> /etc/apt/sources.list \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 6ED0E7B82643E131 \
  && apt-get update -qqy \
  # && apt-get -qqy install chromium=89.0.4389.82-1 \
  # && apt-get -qqy install chromium=90.0.4430.212-1 \
  # && apt-get -qqy install chromium=93.0.4577.82-1 \
  # && apt-get -qqy install chromium=97.0.4692.71-0.1 \
  # && apt-get -qqy install chromium=98.0.4758.102-1+b1 \
  && apt-get -qqy install chromium \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chromium Launch Script Wrapper
#=================================
COPY wrap_chromium_binary /opt/bin/wrap_chromium_binary
RUN /opt/bin/wrap_chromium_binary

#============================================
# Chromium webdriver
#============================================
RUN apt-get update -qqy \
  && apt-get -qqy install chromium-driver \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN echo "chrome" > /opt/selenium/browser_name
RUN chromium --version | awk '{print $2}' > /opt/selenium/browser_version
RUN echo "\"goog:chromeOptions\": {\"binary\": \"/usr/bin/chromium\"}" > /opt/selenium/browser_binary_location

USER 1200

