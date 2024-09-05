#!/bin/bash

function on_exit() {
  local exit_code=$?
  rm -f /tmp/xpi_files.txt
  exit $exit_code
}
trap on_exit EXIT ERR

# Script is used to download language packs for a specific version of Firefox.
# It requires the version number as the first argument and the target directory as the second argument.

VERSION=${1:-$(curl -sk https://product-details.mozilla.org/1.0/firefox_versions.json | jq -r '.LATEST_FIREFOX_VERSION')}
TARGET_DIR="${2:-$(dirname $(readlink -f $(which firefox)))/distribution/extensions}"
BASE_URL="https://ftp.mozilla.org/pub/firefox/releases/$VERSION/linux-x86_64/xpi/"

# Create target directory if it doesn't exist
mkdir -p "${TARGET_DIR}"

# Download the list of files
wget -q -O - "${BASE_URL}" | grep -oP '(?<=href=")[^"]*.xpi' >/tmp/xpi_files.txt

echo "Downloading language packs for Firefox version $VERSION to $TARGET_DIR ..."

# Loop through each file and download it
while IFS= read -r file; do
  file=$(basename "${file}")
  echo "Downloading "${BASE_URL}${file}" ..."
  curl -sk -o "${TARGET_DIR}/${file}" "${BASE_URL}${file}"
  target_file="${TARGET_DIR}/langpack-${file%.xpi}@firefox.mozilla.org.xpi"
  mv "${TARGET_DIR}/${file}" "${target_file}"
  if [ -f "${target_file}" ]; then
    echo "Downloaded ${target_file}"
  fi
done </tmp/xpi_files.txt

echo "All language packs are downloaded to $TARGET_DIR"
