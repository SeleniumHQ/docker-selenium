#!/bin/bash

FIREFOX_DOWNLOAD_URL=$1
FIREFOX_VERSION=$2

function extract_package_tar_bz2() {
  sudo rm -rf /opt/firefox
  tar -C /opt -xjf /tmp/firefox.tar.bz2
  rm -rf /tmp/firefox.tar.bz2
}

function extract_package_tar_xz() {
  sudo rm -rf /opt/firefox
  tar -C /opt -xJf /tmp/firefox.tar.xz
  rm -rf /tmp/firefox.tar.xz
}

function install_package() {
  sudo apt-get -qqy --no-install-recommends install libavcodec-extra libgtk-3-dev libdbus-glib-1-dev xz-utils
  echo "Installing Firefox from package..."
  sudo mv /opt/firefox "/opt/firefox-${FIREFOX_VERSION}"
  sudo mkdir -p "/opt/firefox-${FIREFOX_VERSION}/distribution/extensions"
  sudo ln -fs "/opt/firefox-${FIREFOX_VERSION}/firefox" /usr/bin/firefox
}

if [[ "${FIREFOX_DOWNLOAD_URL}" == *".deb"* ]]; then
  echo "Downloading Firefox from ${FIREFOX_DOWNLOAD_URL}"
  wget -q -O /tmp/firefox.deb "${FIREFOX_DOWNLOAD_URL}"
  echo "Installing Firefox from deb package..."
  sudo apt-get install -y --allow-downgrades -f /tmp/firefox.deb
  rm -f /tmp/firefox.deb
elif [[ "${FIREFOX_DOWNLOAD_URL}" == *".tar.bz2"* ]]; then
  echo "Downloading Firefox from ${FIREFOX_DOWNLOAD_URL}"
  wget -q -O /tmp/firefox.tar.bz2 "${FIREFOX_DOWNLOAD_URL}"
  extract_package_tar_bz2
  install_package
  rm -f /tmp/firefox.tar.bz2
elif [[ "${FIREFOX_DOWNLOAD_URL}" == *".tar.xz"* ]]; then
  echo "Downloading Firefox from ${FIREFOX_DOWNLOAD_URL}"
  wget -q -O /tmp/firefox.tar.xz "${FIREFOX_DOWNLOAD_URL}"
  extract_package_tar_xz
  install_package
  rm -f /tmp/firefox.tar.xz
fi
