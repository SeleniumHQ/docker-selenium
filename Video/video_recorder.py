#!/usr/bin/env python3
"""
Video service entry point that switches between:
1. Unified event-driven service (SE_VIDEO_EVENT_DRIVEN=true)
2. Traditional shell-based polling (SE_VIDEO_EVENT_DRIVEN=false or unset)

When event-driven mode is enabled, this launches a single unified service
that handles both recording and uploading with shared state management.
"""

import os
import signal
import subprocess
import sys


def main():
    event_driven = os.environ.get("SE_VIDEO_EVENT_DRIVEN", "false").lower() == "true"

    if event_driven:
        print("Starting unified event-driven video service...")
        print("This service handles both recording and uploading with shared state.")
        try:
            import asyncio

            from video_service import main as service_main

            asyncio.run(service_main())
        except ImportError as e:
            print(f"Failed to import video service: {e}")
            print("Ensure pyzmq is installed: pip install pyzmq")
            print("Falling back to shell-based recording...")
            _run_shell_recorder()
    else:
        print("Starting shell-based video recording...")
        _run_shell_recorder()


def _run_shell_recorder():
    proc = subprocess.Popen(["/opt/bin/video.sh"])

    def forward_signal(signum, frame):
        try:
            proc.send_signal(signum)
        except ProcessLookupError:
            pass  # Process already exited before signal was forwarded
        proc.wait()

    signal.signal(signal.SIGTERM, forward_signal)
    signal.signal(signal.SIGINT, forward_signal)
    rc = proc.wait()
    if rc != 0:
        sys.exit(rc)


if __name__ == "__main__":
    main()
