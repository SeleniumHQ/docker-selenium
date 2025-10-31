#!/bin/bash

#============================================
# Chrome for Testing Installation Script
#============================================
# This script installs Chrome for Testing from:
# https://googlechromelabs.github.io/chrome-for-testing/
#
# Chrome for Testing is a dedicated Chrome build for testing
# with consistent version matching for ChromeDriver.
#============================================

set -e

# Default Chrome for Testing version
CFT_VERSION="${CFT_VERSION}"
CFT_PLATFORM="${CFT_PLATFORM:-linux64}"
CFT_BASE_URL="https://storage.googleapis.com/chrome-for-testing-public"
CFT_API_BASE="https://googlechromelabs.github.io/chrome-for-testing"

# Resolve channel names to version numbers
if [[ "${CFT_VERSION}" =~ ^(STABLE|BETA|DEV|CANARY)$ ]]; then
  CHANNEL="${CFT_VERSION}"
  echo "Fetching latest ${CHANNEL} version..."
  CFT_VERSION=$(wget -qO- "${CFT_API_BASE}/LATEST_RELEASE_${CHANNEL}" | sed 's/\r$//')
  echo "Resolved ${CHANNEL} to version: ${CFT_VERSION}"
fi

echo "Installing Chrome for Testing: ${CFT_VERSION} (${CFT_PLATFORM})"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Download Chrome for Testing
DOWNLOAD_URL="${CFT_BASE_URL}/${CFT_VERSION}/${CFT_PLATFORM}/chrome-${CFT_PLATFORM}.zip"
echo "Downloading from: ${DOWNLOAD_URL}"

if ! wget -q --spider "${DOWNLOAD_URL}"; then
  echo "Error: Chrome for Testing version ${CFT_VERSION} not found for platform ${CFT_PLATFORM}"
  echo "Please check available versions at: https://googlechromelabs.github.io/chrome-for-testing/"
  rm -rf "${TEMP_DIR}"
  exit 1
fi

wget -q -O chrome.zip "${DOWNLOAD_URL}"

# Extract Chrome
echo "Extracting Chrome for Testing..."
unzip -q chrome.zip

# Install to /opt/chrome
INSTALL_DIR="/opt/chrome"
rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
mv chrome-${CFT_PLATFORM}/* "${INSTALL_DIR}/"

# Create symlink for google-chrome command
ln -sf "${INSTALL_DIR}/chrome" /usr/bin/google-chrome

# Install Chrome dependencies from deb.deps file
echo "Installing Chrome dependencies..."
apt-get update -qqy

if [ -f "${INSTALL_DIR}/deb.deps" ]; then
  echo "Found deb.deps file, parsing dependencies..."
  # Read dependencies from deb.deps file
  # Format: package-name (>= version) or package1 | package2 | package3
  # We need to:
  # 1. Remove version constraints in parentheses
  # 2. Handle alternative packages (take the first one)
  # 3. Remove empty lines and comments
  DEPS=$(cat "${INSTALL_DIR}/deb.deps" |
    grep -v '^#' |
    grep -v '^$' |
    sed 's/ *([^)]*)//g' |
    sed 's/ *|.*//' |
    tr '\n' ' ' |
    sed 's/  */ /g' |
    sed 's/^ *//;s/ *$//' |
    sed 's/libasound2\b/libasound2t64/g')
  echo "Dependencies: ${DEPS}"
  apt-get install -qqy --no-install-recommends ${DEPS}
fi

# Cleanup
cd /
rm -rf "${TEMP_DIR}"
rm -rf /var/lib/apt/lists/* /var/cache/apt/*

echo "Chrome for Testing installation completed"
google-chrome --version
