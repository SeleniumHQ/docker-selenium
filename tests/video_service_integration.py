"""Optional integration check: python -m tests.video_service_integration.

Run inside a video image with an accessible X11 display and writable VIDEO_FOLDER.
Uses loopback HTTP/ZeroMQ, real FFmpeg and local-only rclone copies; no Grid/cloud credentials needed.
"""

import asyncio
import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import zmq
import zmq.asyncio

from Video import video_service as video

state = {"sessions": []}


class StatusHandler(BaseHTTPRequestHandler):
    """Serve controlled Selenium-compatible slot state over real HTTP."""

    def do_GET(self):
        """Reply with current slots. Args: None. Returns: None."""
        slots = [{"session": session} for session in state["sessions"]] or [{"session": None}]
        body = json.dumps({"value": {"nodes": [{"id": "integration-node", "slots": slots}]}}).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        """Silence HTTP logs. Args: format: format string; args: values. Returns: None."""


async def wait_for(predicate):
    """Wait for observable state. Args: predicate: success check. Returns: None or raises after 20 seconds."""
    async with asyncio.timeout(20):
        while not predicate():
            await asyncio.sleep(0.05)


async def main():
    """Verify recording, rollover, finalization and local uploads. Args: None. Returns: None."""
    service = video.VideoService()
    service.display_container = "127.0.0.1"
    service.record_standalone = True
    service.se_server_protocol = "http"
    service.registration_secret = ""
    service.node_poll_interval = 1
    service.configured_video_file_name = "auto"
    service.upload_enabled = True
    service.upload_command = "copy"
    service.upload_destination = str(Path(service.video_folder) / "uploaded")
    server = ThreadingHTTPServer(("127.0.0.1", 0), StatusHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    service.se_node_port = str(server.server_port)
    context = zmq.asyncio.Context()
    publisher = context.socket(zmq.PUB)
    service.event_bus_host = "127.0.0.1"
    service.event_bus_port = str(publisher.bind_to_random_port("tcp://127.0.0.1"))
    subscriber = None

    async def start(session_id):
        """Expose a session without publishing its create. Args: session_id: ID. Returns: Session state."""
        state["sessions"] = [{"sessionId": session_id, "capabilities": {"se:recordVideo": True}}]
        await wait_for(
            lambda: session_id in service.sessions and service.sessions[session_id].ffmpeg_process is not None
        )
        await asyncio.sleep(1)
        session = service.sessions[session_id]
        assert session.ffmpeg_process is not None and session.ffmpeg_process.returncode is None
        return session

    async def upload(expected_id):
        """Verify and copy a queued video locally. Args: expected_id: session ID. Returns: Upload task."""
        task = await asyncio.wait_for(service.upload_queue.get(), 20)
        assert task.session_id == expected_id
        source = Path(task.video_file)
        contents = source.read_bytes()
        assert contents
        await service.process_upload(task)
        assert (Path(task.destination) / source.name).read_bytes() == contents
        return task

    try:
        await asyncio.wait_for(service.wait_for_display(), 10)
        await asyncio.wait_for(service.wait_for_node_ready(), 10)
        subscriber = asyncio.create_task(service.subscribe_events())
        await asyncio.sleep(0.5)

        await start("missed-events")
        state["sessions"] = []
        await upload("missed-events")
        assert service.sessions["missed-events"].close_reason == video.SessionClosedReason.UNKNOWN
        print("PASS: missed events recovered; FFmpeg finalized and rclone copied a readable video", flush=True)

        # Keep status empty so the create must come through the actual event bus.
        created = {"sessionId": "event-session", "nodeId": "integration-node", "capabilities": {"se:recordVideo": True}}
        await publisher.send_multipart([b"session-created", b'""', b"create", json.dumps(created).encode()])
        await wait_for(
            lambda: "event-session" in service.sessions and service.sessions["event-session"].ffmpeg_process is not None
        )
        state["sessions"] = [created]
        await asyncio.sleep(1)
        closed = dict(created, reason="QUIT_COMMAND")
        await publisher.send_multipart([b"session-closed", b'""', b"close", json.dumps(closed).encode()])
        await upload("event-session")
        assert service.sessions["event-session"].close_reason == video.SessionClosedReason.QUIT_COMMAND
        # The closed session stays in status even after full-state cleanup.
        await service._cleanup_session_delayed("event-session", 0)
        await asyncio.sleep(2)
        assert "event-session" not in service.sessions
        assert service.upload_queue.empty()
        print("PASS: real ZeroMQ lifecycle finalizes once; stale status cannot resurrect after cleanup", flush=True)

        service.configured_video_file_name = "shared.mp4"
        old = await start("rollover-old")
        new = await start("rollover-new")
        assert old.ffmpeg_process is None
        assert old.status == video.SessionStatus.CLOSED
        assert old.video_file != new.video_file
        old_path = Path(service.video_folder) / old.video_file
        previous_bytes = old_path.read_bytes()
        await asyncio.sleep(1)
        assert old_path.read_bytes() == previous_bytes
        await upload("rollover-old")
        state["sessions"] = []
        await upload("rollover-new")
        assert service.recorded_count == 4
        assert service.upload_queue.empty()
        print("PASS: lost-close rollover stops old FFmpeg before replacement and preserves both videos", flush=True)
    finally:
        service.shutdown_event.set()
        if subscriber is not None:
            await asyncio.wait_for(subscriber, 20)
        await service.cleanup()
        publisher.close(linger=0)
        context.term()
        await asyncio.to_thread(server.shutdown)
        server.server_close()


if __name__ == "__main__":
    asyncio.run(main())
