#!/bin/bash

#============================================
# ChromeDriver Installation Script
#============================================
# This script installs ChromeDriver with support for:
# - Automatic version detection based on Chrome version
# - Specific version installation
# - Architecture detection
#============================================

set -e

# Default ChromeDriver version (empty for auto-detection)
CHROME_DRIVER_VERSION="${CHROME_DRIVER_VERSION:-}"

echo "Installing ChromeDriver..."

# Detect architecture
DRIVER_ARCH=$(if [ "$(dpkg --print-architecture)" = "amd64" ]; then echo "linux64"; else echo "linux-aarch64"; fi)
echo "Detected architecture: ${DRIVER_ARCH}"

# Determine ChromeDriver version and URL
if [ ! -z "$CHROME_DRIVER_VERSION" ]; then
  # Use specified version
  echo "Using specified ChromeDriver version: ${CHROME_DRIVER_VERSION}"
  CHROME_DRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/$CHROME_DRIVER_VERSION/${DRIVER_ARCH}/chromedriver-${DRIVER_ARCH}.zip"
else
  # Auto-detect version based on Chrome version
  CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/")
  echo "Detected Chrome major version: ${CHROME_MAJOR_VERSION}"

  if [ $CHROME_MAJOR_VERSION -lt 115 ]; then
    # Use old ChromeDriver API for versions < 115
    echo "Getting ChromeDriver latest version from https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION}"
    CHROME_DRIVER_VERSION=$(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION} | sed 's/\r$//')
    CHROME_DRIVER_URL="https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip"
  else
    # Use new Chrome for Testing API for versions >= 115
    echo "Getting ChromeDriver latest version from https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR_VERSION}"
    CHROME_DRIVER_VERSION=$(wget -qO- https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR_VERSION} | sed 's/\r$//')
    CHROME_DRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/$CHROME_DRIVER_VERSION/${DRIVER_ARCH}/chromedriver-${DRIVER_ARCH}.zip"
  fi
fi

echo "Using ChromeDriver from: ${CHROME_DRIVER_URL}"
echo "Using ChromeDriver version: ${CHROME_DRIVER_VERSION}"

# Download and install ChromeDriver
wget --no-verbose -O /tmp/chromedriver_${DRIVER_ARCH}.zip $CHROME_DRIVER_URL

# Remove existing ChromeDriver
rm -rf /opt/selenium/chromedriver

# Extract ChromeDriver
unzip /tmp/chromedriver_${DRIVER_ARCH}.zip -d /opt/selenium
rm /tmp/chromedriver_${DRIVER_ARCH}.zip

# Handle different extraction patterns
if [ -f "/opt/selenium/chromedriver" ]; then
  mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
elif [ -f "/opt/selenium/chromedriver-${DRIVER_ARCH}/chromedriver" ]; then
  mv /opt/selenium/chromedriver-${DRIVER_ARCH}/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
  rm -rf /opt/selenium/chromedriver-${DRIVER_ARCH}
fi

# Set permissions and create symlink
chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

echo "ChromeDriver installation completed"
chromedriver --version
