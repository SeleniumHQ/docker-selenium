#!/bin/bash

# Return error exit code in case of any failure, so supervisord will restart the script
set -e

cleanup_stuck_chrome_processes() {
  echo -n "Killing Chrome processes older than ${SE_BROWSER_LEFTOVERS_PROCESSES_SECS} seconds... "
  ps -e -o pid,etimes,command | grep -v grep | grep chrome/chrome | awk '{if($2>'${SE_BROWSER_LEFTOVERS_PROCESSES_SECS}') print $0}' | awk '{print $1}' | xargs -r kill -9
  echo "DONE."
}

cleanup_tmp_chrome_files() {
  echo -n "Deleting all Chrome files in /tmp... "
  find /tmp -name ".com.google.Chrome.*" -type d -mtime +${SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS} -exec rm -rf "{}" +
  echo "DONE."
}

echo "Chrome cleanup script init with parameters: SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS=${SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS}, SE_BROWSER_LEFTOVERS_PROCESSES_SECS=${SE_BROWSER_LEFTOVERS_PROCESSES_SECS}, SE_BROWSER_LEFTOVERS_INTERVAL_SECS=${SE_BROWSER_LEFTOVERS_INTERVAL_SECS}."

# Start the main loop
while :; do
  echo "Starting cleanup daemon script."

  # Clean up stuck processes
  cleanup_stuck_chrome_processes

  # Wait a few seconds for the processes to stop before removing files
  sleep 5

  # Clean up temporary files
  cleanup_tmp_chrome_files

  # Go to sleep for 1 hour
  echo "Cleanup daemon sleeping for ${SE_BROWSER_LEFTOVERS_INTERVAL_SECS} seconds."
  sleep ${SE_BROWSER_LEFTOVERS_INTERVAL_SECS}
done
