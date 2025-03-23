#!/usr/bin/env bash

SELENIUM_SERVER_PID="$(ps -ef | grep "selenium-server.jar" | grep -v grep | awk '{print $2}')"
LOG_DIR=$1
TIMESTAMP=$(date +%s)

if [ -n "${SELENIUM_SERVER_PID}" ]; then
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
fi
