#!/bin/bash

source /opt/bin/logger.sh

#============================================
# Chrome Components Update Script
#============================================
# This script updates Chrome and ChromeDriver to latest versions
# Can be run at container startup to ensure latest versions
#============================================

set -e

# Check if update is enabled via environment variable
if [ "${SE_UPDATE_CHROME_COMPONENTS}" != "true" ]; then
  log_info "Chrome components update disabled (SE_UPDATE_CHROME_COMPONENTS != true)"
  exit 0
fi

log_info "Starting Chrome components update..."

# Check if we have sudo access
if ! sudo -n true 2>/dev/null; then
  log_warn "No sudo access available. Chrome components update skipped."
  log_info "To enable updates, ensure the container user has sudo privileges."
  exit 0
fi

# Update Chrome if needed
log_info "Checking for Chrome updates..."
CURRENT_CHROME_VERSION=$(google-chrome --version 2>/dev/null || echo "Chrome not found")

if [ "$CURRENT_CHROME_VERSION" = "Chrome not found" ]; then
  log_info "Chrome not found, installing..."
  sudo /opt/bin/install-chrome.sh
else
  log_info "Current Chrome version: $CURRENT_CHROME_VERSION"
  log_info "Updating Chrome to latest version..."
  sudo /opt/bin/install-chrome.sh
  sudo /opt/bin/wrap_chrome_binary
fi

# Update ChromeDriver if needed
log_info "Checking for ChromeDriver updates..."
CURRENT_CHROMEDRIVER_VERSION=$(chromedriver --version 2>/dev/null | head -1 || echo "ChromeDriver not found")

if [ "$CURRENT_CHROMEDRIVER_VERSION" = "ChromeDriver not found" ]; then
  log_info "ChromeDriver not found, installing..."
  sudo /opt/bin/install-chromedriver.sh
else
  log_info "Current ChromeDriver version: $CURRENT_CHROMEDRIVER_VERSION"
  log_info "Updating ChromeDriver to latest compatible version..."
  sudo /opt/bin/install-chromedriver.sh
fi

log_info "Chrome components update completed"
log_info "Final versions:"
google-chrome --version
chromedriver --version
