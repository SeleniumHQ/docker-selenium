#!/usr/bin/env python3
"""
Video service entry point that switches between:
1. Unified event-driven service (SE_VIDEO_EVENT_DRIVEN=true)
2. Traditional shell-based polling (SE_VIDEO_EVENT_DRIVEN=false or unset)

When event-driven mode is enabled, this launches a single unified service
that handles both recording and uploading with shared state management.

After the video service exits for any reason (normal drain, session end, or
supervisord-initiated shutdown), this controller signals supervisord so the
container shuts down.  Centralising this here means both shell and event-driven
modes have identical container-lifecycle behaviour without video.sh needing to
know about supervisord.
"""

import os
import signal
import subprocess
import sys
import time


def _signal_supervisord() -> None:
    """Signal supervisord to initiate a container-wide shutdown.

    Safe to call even when supervisord is already shutting down — it will
    simply ignore a repeated SIGTERM if it is already in SHUTDOWN state.
    """
    pid_file = os.environ.get("SE_SUPERVISORD_PID_FILE", "")
    if not pid_file:
        return
    try:
        with open(pid_file) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        print("[video.recorder] - Signaled supervisord to shut down")
    except (OSError, ValueError, FileNotFoundError):
        pass


def main():
    event_driven = os.environ.get("SE_VIDEO_EVENT_DRIVEN", "false").lower() == "true"

    if event_driven:
        print("Starting unified event-driven video service...")
        print("This service handles both recording and uploading with shared state.")

        # Capture whether shutdown was externally initiated (SIGTERM/SIGINT)
        # before asyncio.run() replaces the signal handlers via add_signal_handler.
        _external_shutdown = [False]

        def _mark_external_shutdown(signum, frame):
            _external_shutdown[0] = True
            # This handler is only reachable before asyncio.run() installs its
            # own handlers via loop.add_signal_handler().  Setting the flag and
            # returning would swallow the signal — nothing would act on it and
            # the process would hang inside asyncio.run() indefinitely.
            # Exit immediately so supervisord sees a clean stop.
            sys.exit(0)

        signal.signal(signal.SIGTERM, _mark_external_shutdown)
        signal.signal(signal.SIGINT, _mark_external_shutdown)

        try:
            import asyncio

            from video_service import main as service_main

            asyncio.run(service_main())
        except ImportError as e:
            print(f"Failed to import video service: {e}")
            print("Ensure pyzmq is installed: pip install pyzmq")
            print("Falling back to shell-based recording...")
            _run_shell_recorder()
            return

        # Only trigger container shutdown for self-initiated exits (drain).
        if not _external_shutdown[0]:
            _signal_supervisord()
    else:
        print("Starting shell-based video recording...")
        _run_shell_recorder()


def _run_shell_recorder():
    record_video = os.environ.get("SE_RECORD_VIDEO", "true").lower() == "true"
    per_session_mode = os.environ.get("SE_VIDEO_FILE_NAME", "") == "auto"

    if not record_video and not per_session_mode:
        print("[video.recorder] - SE_RECORD_VIDEO is disabled and SE_VIDEO_FILE_NAME is not 'auto', idling.")
        try:
            while True:
                time.sleep(60)
        except KeyboardInterrupt:
            pass
        return

    proc = subprocess.Popen(["/opt/bin/video.sh"])
    _external_shutdown = False  # True when supervisord (or user) told us to stop

    def forward_signal(signum, frame):
        nonlocal _external_shutdown
        if not _external_shutdown:
            _external_shutdown = True
            try:
                proc.send_signal(signum)
            except ProcessLookupError:
                pass
        # Do NOT call proc.wait() here — blocking inside a signal handler
        # interferes with bash's deferred-signal queue.  The main-flow
        # proc.wait() below resumes automatically after this returns (PEP 475).

    signal.signal(signal.SIGTERM, forward_signal)
    signal.signal(signal.SIGINT, forward_signal)
    rc = proc.wait()

    # Signal supervisord only for self-initiated exits (drain, node gone).
    # If the shutdown came FROM supervisord (_external_shutdown=True) it is
    # already in SHUTDOWN state — signalling it again is a no-op at best and
    # confusing at worst.  If the recorder crashed (rc != 0) we must not bring
    # down the Selenium process alongside it.
    if not _external_shutdown and rc == 0:
        _signal_supervisord()

    if rc != 0:
        sys.exit(rc)


if __name__ == "__main__":
    main()
