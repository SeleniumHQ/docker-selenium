#!/usr/bin/env bash

SELENIUM_SERVER_PID=$1
LOG_DIR=$2
TIMESTAMP=$(date +%s)

filename="$LOG_DIR/dump_pid${SELENIUM_SERVER_PID}_${TIMESTAMP}.hprof"
if ps -p "${SELENIUM_SERVER_PID}" >/dev/null; then
  echo "Server process is still running. Create heap dump by using jmap"
  jmap -dump:live,format=b,file="${filename}" "${SELENIUM_SERVER_PID}"
else
  filename_source="$LOG_DIR/java_pid${SELENIUM_SERVER_PID}.hprof"
  if [ -f "$filename_source" ]; then
    echo "Server is not running. Check HeapDumpOnOutOfMemoryError created"
    mv "$filename_source" "$filename"
  else
    echo "Server is not running. No heap dump is created"
  fi
fi
