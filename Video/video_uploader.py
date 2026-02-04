#!/usr/bin/env python3
"""
Video uploader entry point that switches between:
1. No-op when SE_EVENT_DRIVEN_SERVICES=true (unified service handles uploads)
2. Traditional shell-based upload (SE_EVENT_DRIVEN_SERVICES=false or unset)

When event-driven mode is enabled, the unified video_service.py handles both
recording and uploading, so this process should not run or should exit immediately.
"""

import os
import subprocess
import sys
import time


def main():
    event_driven = os.environ.get("SE_EVENT_DRIVEN_SERVICES", "false").lower() == "true"

    if event_driven:
        print("Event-driven mode enabled.")
        print("Upload is handled by the unified video_service.py - this process will idle.")
        print("To disable this, set SE_EVENT_DRIVEN_SERVICES=false")

        # Keep process alive but idle (supervisord expects it to run)
        # The actual uploading is done by video_service.py
        try:
            while True:
                time.sleep(60)
        except KeyboardInterrupt:
            print("Uploader process exiting...")
            sys.exit(0)
    else:
        print("Starting shell-based video upload...")
        subprocess.run(["/opt/bin/upload.sh"], check=True)


if __name__ == "__main__":
    main()
