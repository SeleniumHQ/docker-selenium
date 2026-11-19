#!/bin/bash
# Installs the latest a8m/envsubst release for the runner architecture.
set -e

echo "Installing envsubst for AMD64 / ARM64"
ENVSUBST_VERSION="$(curl -s -L -o /dev/null -w '%{url_effective}\n' https://github.com/a8m/envsubst/releases/latest | sed -E 's#.*/tag/v([0-9.]+).*#\1#')"
ARCH=$(if [ "$(dpkg --print-architecture)" = "amd64" ]; then echo "x86_64"; else echo "$(dpkg --print-architecture)"; fi)
curl -fsSL "https://github.com/a8m/envsubst/releases/download/v${ENVSUBST_VERSION}/envsubst-$(uname -s)-${ARCH}" -o envsubst
chmod +x envsubst
sudo mv envsubst /usr/local/bin
sudo ln -sf /usr/local/bin/envsubst /usr/bin/envsubst
envsubst --version 2>/dev/null || command -v envsubst
