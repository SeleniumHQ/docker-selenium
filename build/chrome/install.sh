#!/bin/bash
set -e
set -x

#===============
# Google Chrome
#===============
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list

apt-get update -qqy

apt-get -qqy --no-install-recommends install \
	google-chrome-stable

rm /etc/apt/sources.list.d/google-chrome.list

#==================
# Chrome webdriver
#==================
CHROME_DRIVER_VERSION=2.12

wget --no-verbose -O /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip

rm -rf /opt/selenium/chromedriver
unzip /tmp/chromedriver_linux64.zip -d /opt/selenium
rm /tmp/chromedriver_linux64.zip

mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#==================
# Selenium Configuration
#==================
cp /tmp/build/chrome/config.json /opt/selenium/config.json
#cp -rT /tmp/build/chrome/etc/ /etc/
