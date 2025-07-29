#!/bin/bash

#============================================
# Chrome Components Update Script
#============================================
# This script updates Chrome and ChromeDriver to latest versions
# Can be run at container startup to ensure latest versions
#============================================

set -e

# Check if update is enabled via environment variable
if [ "${SE_UPDATE_CHROME_COMPONENTS}" != "true" ]; then
  echo "Chrome components update disabled (SE_UPDATE_CHROME_COMPONENTS != true)"
  exit 0
fi

echo "Starting Chrome components update..."

# Check if we have sudo access
if ! sudo -n true 2>/dev/null; then
  echo "Warning: No sudo access available. Chrome components update skipped."
  echo "To enable updates, ensure the container user has sudo privileges."
  exit 0
fi

# Update Chrome if needed
echo "Checking for Chrome updates..."
CURRENT_CHROME_VERSION=$(google-chrome --version 2>/dev/null || echo "Chrome not found")

if [ "$CURRENT_CHROME_VERSION" = "Chrome not found" ]; then
  echo "Chrome not found, installing..."
  sudo /opt/bin/install-chrome.sh
else
  echo "Current Chrome version: $CURRENT_CHROME_VERSION"
  echo "Updating Chrome to latest version..."
  sudo /opt/bin/install-chrome.sh
  sudo /opt/bin/wrap_chrome_binary
fi

# Update ChromeDriver if needed
echo "Checking for ChromeDriver updates..."
CURRENT_CHROMEDRIVER_VERSION=$(chromedriver --version 2>/dev/null | head -1 || echo "ChromeDriver not found")

if [ "$CURRENT_CHROMEDRIVER_VERSION" = "ChromeDriver not found" ]; then
  echo "ChromeDriver not found, installing..."
  sudo /opt/bin/install-chromedriver.sh
else
  echo "Current ChromeDriver version: $CURRENT_CHROMEDRIVER_VERSION"
  echo "Updating ChromeDriver to latest compatible version..."
  sudo /opt/bin/install-chromedriver.sh
fi

echo "Chrome components update completed"
echo "Final versions:"
google-chrome --version
chromedriver --version
