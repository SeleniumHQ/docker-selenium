#!/bin/bash

cleanup_tmp_chrome_files() {
  echo -n "Deleting all Chrome files in /tmp... "
  find /tmp -name ".com.google.Chrome.*" -type d -mtime +1 -exec rm -rf {} +
  echo "DONE."
}

cleanup_stuck_chrome_processes() {
  echo -n "Killing Chrome processes older than 2 hours... "
  ps -e -o pid,etimes,command | grep -v grep | grep chrome/chrome | awk '{if($2>1200) print $0}' | awk '{print $1}' | xargs -r kill -9
  echo "DONE."
}

# Start the main loop
while :
do
  echo "Starting cleanup daemon script."

  # Clean up stuck processes
  cleanup_stuck_chrome_processes

  sleep 5

  # Clean up temporary files
  cleanup_tmp_chrome_files

  # Go to sleep for 1 hour
  echo "Cleanup daemon sleeping for 1 hour."
  sleep 3600
done
