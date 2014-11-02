################
# Headless e2e #
################
FROM ubuntu:14.04.1
MAINTAINER Leo Gallucci <elgalu3@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

#================================================
# Make sure the package repository is up to date
#================================================
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe\n" > /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty-updates main universe\n" >> /etc/apt/sources.list
RUN apt-get -qqy update
# Let's make the upgrade even though it is still unclear to me
# if the upgrade is convenient or not
RUN apt-get -qqy upgrade

#========================
# Miscellaneous packages
#========================
RUN apt-get -qqy install ca-certificates curl wget unzip vim

#=================
# Locale settings
#=================
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8
# Reconfigure
RUN dpkg-reconfigure --frontend noninteractive locales
RUN apt-get -qqy install language-pack-en

#===================
# Timezone settings
#===================
ENV TZ "US/Pacific"
RUN echo "US/Pacific" | sudo tee /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

#==============
# VNC and Xvfb
#==============
RUN apt-get -qqy install x11vnc xvfb

#======
# Java
#======
# Minimal runtime used for executing non GUI Java programs
RUN apt-get -qqy install openjdk-7-jre-headless

#=======
# Fonts
#=======
RUN apt-get -qqy install fonts-ipafont-gothic xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic

#===========================
# Some directories creation
#===========================
RUN mkdir -p ~/.vnc
RUN mkdir -p /opt/selenium

#==========
# Selenium
#==========
RUN (cd /tmp; wget --no-verbose -O /opt/selenium/selenium-server-standalone.jar \
     http://selenium-release.storage.googleapis.com/2.44/selenium-server-standalone-2.44.0.jar)

#==================
# Chrome webdriver
#==================
ENV CHROME_DRIVER_VERSION 2.12
RUN (cd /tmp; wget --no-verbose -O chromedriver_linux64.zip \
     http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip)
RUN (cd /opt/selenium; rm -rf chromedriver; unzip /tmp/chromedriver_linux64.zip)
RUN rm /tmp/chromedriver_linux64.zip
RUN mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
RUN chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
RUN ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#=========
# fluxbox
#=========
# A fast, lightweight and responsive window manager
RUN apt-get -qqy install fluxbox

#===============
# Google Chrome
#===============
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -qqy update
RUN apt-get -qqy install google-chrome-stable

#=================
# Mozilla Firefox
#=================
RUN apt-get -qqy install firefox

#========================
# Configure VNC password
#========================
RUN x11vnc -storepasswd secret ~/.vnc/passwd

#========================================
# Add normal user with passwordless sudo
#========================================
RUN sudo useradd user1 --shell /bin/bash --create-home
RUN sudo usermod -a -G sudo user1 && \
    echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

#====================================================================
# Script to run selenium standalone server for Chrome and/or Firefox
#====================================================================
ADD ./bin/entry_point.sh /opt/selenium/entry_point.sh
ADD ./bin/local-sel-headless.sh /opt/selenium/local-sel-headless.sh
RUN chmod +x /opt/selenium/entry_point.sh
RUN chmod +x /opt/selenium/local-sel-headless.sh

#===========
# DNS stuff
#===========
ADD ./etc/hosts /tmp/hosts
# Below hack is no longer necessary since docker >= 1.2.0, commented to ease old users transition
#  Poor man /etc/hosts updates until https://github.com/dotcloud/docker/issues/2267
#  Ref: https://stackoverflow.com/questions/19414543/how-can-i-make-etc-hosts-writable-by-root-in-a-docker-container
#  RUN mkdir -p -- /lib-override && cp /lib/x86_64-linux-gnu/libnss_files.so.2 /lib-override
#  RUN perl -pi -e 's:/etc/hosts:/tmp/hosts:g' /lib-override/libnss_files.so.2
#  ENV LD_LIBRARY_PATH /lib-override

#============================
# Some configuration options
#============================
ENV SCREEN_WIDTH 1360
ENV SCREEN_HEIGHT 1020
ENV SCREEN_DEPTH 24
ENV SELENIUM_PORT 4444
ENV DISPLAY :20.0

#================================
# Expose Container's Directories
#================================
VOLUME /var/log

#================================
# Expose Container's Ports
#================================
EXPOSE 4444 5900

#===================
# CMD or ENTRYPOINT
#===================
# Start a selenium standalone server for Chrome and/or Firefox
CMD ["/opt/selenium/entry_point.sh"]
