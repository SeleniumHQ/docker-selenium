#!/usr/bin/env python3
"""
Video service entry point that switches between:
1. Unified event-driven service (SE_EVENT_DRIVEN_SERVICES=true)
2. Traditional shell-based polling (SE_EVENT_DRIVEN_SERVICES=false or unset)

When event-driven mode is enabled, this launches a single unified service
that handles both recording and uploading with shared state management.
"""

import os
import subprocess
import sys


def main():
    event_driven = os.environ.get("SE_EVENT_DRIVEN_SERVICES", "false").lower() == "true"

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
            subprocess.run(["/opt/bin/video.sh"], check=True)
    else:
        print("Starting shell-based video recording...")
        subprocess.run(["/opt/bin/video.sh"], check=True)


if __name__ == "__main__":
    main()
