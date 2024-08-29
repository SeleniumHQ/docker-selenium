#!/bin/bash

# Return error exit code in case of any failure, so supervisord will restart the script
set -e

cleanup_stuck_firefox_processes() {
  echo -n "Killing Firefox processes older than ${SE_BROWSER_LEFTOVERS_PROCESSES_SECS} seconds... "
  ps -e -o pid,etimes,command | grep -v grep | grep firefox-bin | awk '{if($2>'${SE_BROWSER_LEFTOVERS_PROCESSES_SECS}') print $0}' | awk '{print $1}' | xargs -r kill -9
  echo "DONE."
}

echo "Firefox cleanup script init with parameters: SE_BROWSER_LEFTOVERS_PROCESSES_SECS=${SE_BROWSER_LEFTOVERS_PROCESSES_SECS}, SE_BROWSER_LEFTOVERS_INTERVAL_SECS=${SE_BROWSER_LEFTOVERS_INTERVAL_SECS}."

# Start the main loop
while :; do
  echo "Starting cleanup daemon script."

  # Clean up stuck processes
  cleanup_stuck_firefox_processes

  # Go to sleep for 1 hour
  echo "Cleanup daemon sleeping for ${SE_BROWSER_LEFTOVERS_INTERVAL_SECS} seconds."
  sleep ${SE_BROWSER_LEFTOVERS_INTERVAL_SECS}
done
