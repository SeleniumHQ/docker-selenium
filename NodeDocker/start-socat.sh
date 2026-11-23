#!/usr/bin/env bash

source /opt/bin/logger.sh

# set -e: exit asap if a command exits with a non-zero status
set -e

if stat /var/run/docker.sock; then
  log_info "Starting socat, docker.sock found."
  sudo socat TCP-L:2375,bind=127.0.0.1,fork,reuseaddr UNIX:/var/run/docker.sock
else
  log_warn "docker.sock not found."
fi
