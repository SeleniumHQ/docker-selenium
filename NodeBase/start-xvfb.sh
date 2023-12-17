#!/usr/bin/env bash

SCREEN_WIDTH=${SCREEN_WIDTH:-$SE_SCREEN_WIDTH}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-$SE_SCREEN_HEIGHT}
SCREEN_DEPTH=${SCREEN_DEPTH:-$SE_SCREEN_DEPTH}
SCREEN_DPI=${SCREEN_DPI:-$SE_SCREEN_DPI}

if [ "${START_XVFB:-$SE_START_XVFB}" = true ] ; then
  export GEOMETRY="${SCREEN_WIDTH}""x""${SCREEN_HEIGHT}""x""${SCREEN_DEPTH}"

  rm -f /tmp/.X*lock

  # Command reference
  # http://manpages.ubuntu.com/manpages/focal/man1/xvfb-run.1.html
  # http://manpages.ubuntu.com/manpages/focal/man1/Xvfb.1.html
  # http://manpages.ubuntu.com/manpages/focal/man1/Xserver.1.html
  /usr/bin/xvfb-run --server-num=${DISPLAY_NUM} \
    --listen-tcp \
    --server-args="-screen 0 ${GEOMETRY} -fbdir /var/tmp -dpi ${SCREEN_DPI} -listen tcp -noreset -ac +extension RANDR" \
    /usr/bin/fluxbox -display ${DISPLAY}
else
  echo "Xvfb and Fluxbox won't start. Chrome/Firefox/Edge/Chromium can only run in headless mode. Remember to set the 'headless' flag in your test."
fi
