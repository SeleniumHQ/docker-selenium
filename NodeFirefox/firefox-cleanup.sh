#!/bin/bash

source /opt/bin/logger.sh

# Return error exit code in case of any failure, so supervisord will restart the script
set -e

cleanup_stuck_firefox_processes() {
  log_info "Killing Firefox processes older than ${SE_BROWSER_LEFTOVERS_PROCESSES_SECS} seconds..."
  ps -e -o pid,etimes,command | grep -v grep | grep firefox-bin | awk '{if($2>'${SE_BROWSER_LEFTOVERS_PROCESSES_SECS}') print $0}' | awk '{print $1}' | xargs -r kill -9
  log_info "DONE."
}

log_info "Firefox cleanup script init with parameters: SE_BROWSER_LEFTOVERS_PROCESSES_SECS=${SE_BROWSER_LEFTOVERS_PROCESSES_SECS}, SE_BROWSER_LEFTOVERS_INTERVAL_SECS=${SE_BROWSER_LEFTOVERS_INTERVAL_SECS}."

# Start the main loop
while :; do
  log_info "Starting cleanup daemon script."

  # Clean up stuck processes
  cleanup_stuck_firefox_processes

  # Go to sleep for 1 hour
  log_info "Cleanup daemon sleeping for ${SE_BROWSER_LEFTOVERS_INTERVAL_SECS} seconds."
  sleep ${SE_BROWSER_LEFTOVERS_INTERVAL_SECS}
done
