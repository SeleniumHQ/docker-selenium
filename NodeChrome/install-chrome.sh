#!/bin/bash

#============================================
# Google Chrome Installation Script
#============================================
# This script installs Google Chrome with support for:
# - Different channels (stable, beta, unstable)
# - Specific versions
# - Architecture detection
#============================================

set -e

# Default Chrome version/channel
CHROME_VERSION="${CHROME_VERSION:-google-chrome-stable}"

echo "Installing Google Chrome: ${CHROME_VERSION}"

# Add Google Chrome repository
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/trusted.gpg.d/google.gpg >/dev/null
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >>/etc/apt/sources.list.d/google-chrome.list

# Update package list
apt-get update -qqy

# Install Chrome based on version specification
if echo "${CHROME_VERSION}" | grep -qE "google-chrome-stable[_|=][0-9]*"; then
  # Install specific version
  CHROME_VERSION=$(echo "$CHROME_VERSION" | tr '=' '_')
  echo "Installing specific Chrome version: ${CHROME_VERSION}"
  wget -qO google-chrome.deb "https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/${CHROME_VERSION}_$(dpkg --print-architecture).deb"
  apt-get -qqy --no-install-recommends install --allow-downgrades ./google-chrome.deb
  rm -rf google-chrome.deb
else
  # Install from repository (stable, beta, unstable)
  echo "Installing Chrome channel: ${CHROME_VERSION}"
  apt-get -qqy --no-install-recommends install ${CHROME_VERSION}
fi

# Cleanup
rm /etc/apt/sources.list.d/google-chrome.list
rm -rf /var/lib/apt/lists/* /var/cache/apt/*

echo "Google Chrome installation completed"
google-chrome --version
