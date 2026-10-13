#!/usr/bin/env bash

#============================================
# ChromeDriver source resolution
#============================================
# Decides where a ChromeDriver comes from for a given architecture.
#
# Chrome for Testing (CfT) is the preferred source everywhere it publishes a build: it is
# Google's own, it is versioned in lockstep with Chrome, and it needs none of the extra
# shared libraries or the glibc upgrade that the Debian `chromium-driver` package does.
# CfT began publishing `linux-arm64` with Chrome 153, alongside linux64, mac-arm64,
# mac-x64, win32 and win64.
#
# Before Chrome 153 there is no arm64 build there, so the Debian chromium-driver package -
# archived per version at https://github.com/NDViet/chromium-stable - remains the fallback
# for anything pinned to an older major.
#
# Usage:   resolve-chromedriver-source.sh <dpkg-arch> <chrome-major> [explicit-version]
# Prints:  "cft <cft-platform> <version>"  to install from Chrome for Testing
#          "chromium-package"              to install the Debian chromium-driver package
# Exits:   non-zero on amd64 when CfT cannot be reached. amd64 has always had a linux64
#          build, so a failed probe there means the network is wrong, not the archive -
#          and quietly diverting amd64 onto a third-party Debian archive would be a much
#          worse outcome than stopping.
#============================================

set -euo pipefail

CFT_LATEST_RELEASE_URL="${CFT_LATEST_RELEASE_URL:-https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE}"
CFT_DOWNLOAD_URL="${CFT_DOWNLOAD_URL:-https://storage.googleapis.com/chrome-for-testing-public}"

ARCH="${1:-}"
CHROME_MAJOR_VERSION="${2:-}"
EXPLICIT_VERSION="${3:-}"

case "${ARCH}" in
amd64) CFT_PLATFORM="linux64" ;;
arm64) CFT_PLATFORM="linux-arm64" ;;
*) CFT_PLATFORM="" ;;
esac

fall_back() {
  # amd64 has no fallback, by design. See the header.
  if [ "${ARCH}" = "amd64" ]; then
    echo "resolve-chromedriver-source: no Chrome for Testing build for amd64 ($1)" >&2
    exit 1
  fi
  echo "chromium-package"
  exit 0
}

if [ -z "${CFT_PLATFORM}" ]; then
  fall_back "unsupported architecture ${ARCH}"
fi

VERSION="${EXPLICIT_VERSION}"

if [ -z "${VERSION}" ]; then
  if ! VERSION=$(wget -qO- "${CFT_LATEST_RELEASE_URL}_${CHROME_MAJOR_VERSION}" | sed 's/\r$//'); then
    fall_back "no released version for major ${CHROME_MAJOR_VERSION}"
  fi
fi

if [ -z "${VERSION}" ]; then
  fall_back "no released version for major ${CHROME_MAJOR_VERSION}"
fi

if ! wget -q --spider "${CFT_DOWNLOAD_URL}/${VERSION}/${CFT_PLATFORM}/chromedriver-${CFT_PLATFORM}.zip"; then
  fall_back "no ${CFT_PLATFORM} build for ${VERSION}"
fi

echo "cft ${CFT_PLATFORM} ${VERSION}"
