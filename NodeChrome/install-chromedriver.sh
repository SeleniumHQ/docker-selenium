#!/bin/bash

#============================================
# ChromeDriver Installation Script
#============================================
# This script installs ChromeDriver with support for:
# - Automatic version detection based on Chrome version
# - Specific version installation
# - Architecture detection
#
# On amd64 the driver is downloaded from Chrome for Testing (CfT). Google does not
# publish a ChromeDriver build for Linux/ARM64, so on other architectures the driver
# is taken from the Debian `chromium-driver` package, which is built from the same
# Chromium source and drives Google Chrome of the same major version. Those packages
# are archived per version at https://github.com/NDViet/chromium-stable
#
# CHROME_DRIVER_VERSION is a CfT version on amd64 (e.g. 151.0.7922.71) and a Debian
# package version elsewhere (e.g. 151.0.7922.47-1).
#============================================

set -e

# Default ChromeDriver version (empty for auto-detection)
CHROME_DRIVER_VERSION="${CHROME_DRIVER_VERSION:-}"
CHROMIUM_ARCHIVE_SITE="${CHROMIUM_ARCHIVE_SITE:-https://github.com/NDViet/chromium-stable}"
CHROMIUM_MATRIX_URL="${CHROMIUM_MATRIX_URL:-https://raw.githubusercontent.com/NDViet/chromium-stable/refs/heads/main/browser-matrix.yml}"
CHROMIUM_DEB_SITE="${CHROMIUM_DEB_SITE:-http://deb.debian.org/debian}"

echo "Installing ChromeDriver..."

# Detect architecture
ARCH=$(dpkg --print-architecture)
echo "Detected architecture: ${ARCH}"

if [ "${ARCH}" = "amd64" ]; then
  DRIVER_ARCH="linux64"

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
else
  # Determine the Chromium driver package version, it has to match the Chrome major version
  if [ ! -z "$CHROME_DRIVER_VERSION" ]; then
    echo "Using specified Chromium driver package version: ${CHROME_DRIVER_VERSION}"
    CHROME_DRIVER_PACKAGE_VERSION="${CHROME_DRIVER_VERSION}"
  else
    CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/")
    echo "Detected Chrome major version: ${CHROME_MAJOR_VERSION}"
    echo "Google does not build ChromeDriver for linux/${ARCH}, getting the Chromium driver version from ${CHROMIUM_MATRIX_URL}"
    CHROME_DRIVER_PACKAGE_VERSION=$(wget -qO- "${CHROMIUM_MATRIX_URL}" |
      awk -v major="'${CHROME_MAJOR_VERSION}':" '$1 == major {found=1; next} found && $1 == "CHROMIUM_PACKAGE_VERSION:" {print $2; exit}')
    if [ -z "${CHROME_DRIVER_PACKAGE_VERSION}" ]; then
      echo "Chromium driver package for major version ${CHROME_MAJOR_VERSION} is not available yet, it can not be installed on linux/${ARCH}" >&2
      exit 1
    fi
  fi

  # Debian package versions carry a revision suffix, e.g. 151.0.7922.47-1
  CHROME_DRIVER_VERSION="${CHROME_DRIVER_PACKAGE_VERSION%-*}"
  CHROME_DRIVER_URL="${CHROMIUM_ARCHIVE_SITE}/releases/download/${CHROME_DRIVER_PACKAGE_VERSION}/chromium-driver_${CHROME_DRIVER_PACKAGE_VERSION}_${ARCH}.deb"

  echo "Using ChromeDriver from: ${CHROME_DRIVER_URL}"
  echo "Using ChromeDriver version: ${CHROME_DRIVER_VERSION}"

  # Download ChromeDriver, the package only ships /usr/bin/chromedriver
  wget --no-verbose -O /tmp/chromium-driver.deb $CHROME_DRIVER_URL

  # Remove existing ChromeDriver
  rm -rf /opt/selenium/chromedriver /tmp/chromium-driver

  # Extract ChromeDriver
  dpkg -x /tmp/chromium-driver.deb /tmp/chromium-driver
  mv /tmp/chromium-driver/usr/bin/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
  rm -rf /tmp/chromium-driver /tmp/chromium-driver.deb
  chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION

  # Shared libraries the Chromium driver links against and Google Chrome does not pull in
  apt-get update -qqy
  apt-get -qqy --no-install-recommends install libdouble-conversion3 libminizip1t64
  rm -rf /var/lib/apt/lists/* /var/cache/apt/*

  # The Chromium driver is built on Debian unstable and can require a newer glibc than
  # the base image ships. Only upgrade libc6 when the driver refuses to start.
  if ! /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION --version >/dev/null 2>&1; then
    echo "ChromeDriver requires a newer glibc than the base image provides, installing libc6 from Debian"
    echo "deb ${CHROMIUM_DEB_SITE}/ sid main" >/etc/apt/sources.list.d/debian.list
    wget -qO- https://ftp-master.debian.org/keys/archive-key-12.asc | gpg --dearmor >/etc/apt/trusted.gpg.d/debian-archive-keyring.gpg
    for d in bin lib lib32 lib64 libo32 libx32 sbin; do dpkg-divert --package base-files --no-rename --remove /$d; done
    apt-get update -qqy
    apt-get -qqy install libc6
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /etc/apt/sources.list.d/debian.list
  fi
fi

# Set permissions and create symlink
chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION
ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

echo "ChromeDriver installation completed"
chromedriver --version
