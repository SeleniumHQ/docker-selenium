#!/usr/bin/env python3
"""
Unified event-driven video recording and upload service for Selenium Grid.

This service combines video recording and uploading into a single process with:
- Shared session state management
- Internal async queue for upload tasks
- Direct communication between recorder and uploader
- No tmp files or named pipes needed for internal coordination

Subscribes to the Grid's ZeroMQ event bus and handles:
- SessionCreatedEvent: Start video recording
- SessionClosedEvent: Stop recording, queue upload
- SessionEvent: Track custom events (e.g., test:failed)

    Environment Variables:
    SE_EVENT_BUS_HOST: Event bus hostname (default: localhost)
    SE_EVENT_BUS_PUBLISH_PORT: Port to subscribe for events (default: 4442)
    SE_EVENT_BUS_CONNECT_TIMEOUT_MS: ZMQ connect timeout in ms (default: 5000)
    SE_EVENT_BUS_RECONNECT_INTERVAL_MS: ZMQ reconnect interval in ms (default: 1000)
    SE_EVENT_BUS_RECONNECT_INTERVAL_MAX_MS: ZMQ max reconnect interval in ms (default: 5000)
    SE_REGISTRATION_SECRET: Secret for event bus authentication
    SE_NODE_PORT: Node port for /status endpoint (default: 5555)
    SE_SERVER_PROTOCOL: Protocol for Node /status endpoint (default: http)
    SE_ROUTER_USERNAME, SE_ROUTER_PASSWORD: Optional Basic Auth credentials for Grid endpoints
    SE_RETAIN_ON_FAILURE: Discard recordings for sessions that pass (default: false)
    SE_FAILURE_SESSION_EVENTS: Comma-separated event substrings that mark a session as failed
    VIDEO_FOLDER: Directory to store video files
    SE_VIDEO_FILE_NAME: Fixed video file name ("auto" keeps per-session naming)
    SE_UPLOAD_DESTINATION_PREFIX: Remote upload destination prefix; upload is enabled when non-empty
    SE_SCREEN_WIDTH, SE_SCREEN_HEIGHT: Screen dimensions
    SE_FRAME_RATE: Video frame rate (default: 15)
"""

import asyncio
import base64
import json
import logging
import os
import re
import signal
import ssl
import sys
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.error import URLError
from urllib.request import Request, urlopen

import zmq
import zmq.asyncio

# Configure logging
LOG_FORMAT = "%(asctime)s [video.service] - %(message)s"
LOG_DATEFMT = os.environ.get("SE_LOG_TIMESTAMP_FORMAT", "%Y-%m-%d %H:%M:%S,%f")[:-3]
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT, datefmt=LOG_DATEFMT)
logger = logging.getLogger(__name__)


class SessionClosedReason(Enum):
    """Reasons why a session was closed."""

    QUIT_COMMAND = "QUIT_COMMAND"
    TIMEOUT = "TIMEOUT"
    NODE_REMOVED = "NODE_REMOVED"
    NODE_RESTARTED = "NODE_RESTARTED"


class SessionStatus(Enum):
    """Session lifecycle status."""

    CREATED = auto()
    RECORDING = auto()
    STOPPING = auto()
    CLOSED = auto()


@dataclass
class UploadTask:
    """Represents a video upload task."""

    session_id: str
    video_file: str
    destination: str


@dataclass
class SessionState:
    """Complete state for a session."""

    session_id: str
    status: SessionStatus = SessionStatus.CREATED
    capabilities: Dict[str, Any] = field(default_factory=dict)
    video_file: Optional[str] = None
    ffmpeg_process: Optional[asyncio.subprocess.Process] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    close_reason: Optional[SessionClosedReason] = None
    record_video: bool = True
    has_failure_event: bool = False
    failure_events: List[str] = field(default_factory=list)
    test_name: str = ""
    retain_on_failure: bool = False

    @property
    def is_failed(self) -> bool:
        """Check if session is considered failed."""
        if self.has_failure_event:
            return True
        if self.close_reason and self.close_reason != SessionClosedReason.QUIT_COMMAND:
            return True
        return False

    @property
    def duration_seconds(self) -> Optional[float]:
        """Get session duration in seconds."""
        if self.start_time and self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return None


class VideoService:
    """Unified video recording and upload service."""

    def __init__(self):
        # Event bus configuration
        self.event_bus_host = os.environ.get("SE_EVENT_BUS_HOST", "localhost")
        self.event_bus_port = os.environ.get("SE_EVENT_BUS_PUBLISH_PORT", "4442")
        self.event_bus_connect_timeout_ms = int(os.environ.get("SE_EVENT_BUS_CONNECT_TIMEOUT_MS", "5000"))
        self.event_bus_reconnect_interval_ms = int(os.environ.get("SE_EVENT_BUS_RECONNECT_INTERVAL_MS", "1000"))
        self.event_bus_reconnect_interval_max_ms = int(os.environ.get("SE_EVENT_BUS_RECONNECT_INTERVAL_MAX_MS", "5000"))
        self.registration_secret = os.environ.get("SE_REGISTRATION_SECRET", "")
        self.router_username = os.environ.get("SE_ROUTER_USERNAME", "")
        self.router_password = os.environ.get("SE_ROUTER_PASSWORD", "")

        # Video recording configuration
        self.video_folder = os.environ.get("VIDEO_FOLDER", "/videos")
        self.screen_width = os.environ.get("SE_SCREEN_WIDTH", "1920")
        self.screen_height = os.environ.get("SE_SCREEN_HEIGHT", "1080")
        self.frame_rate = os.environ.get("SE_FRAME_RATE", "15")
        self.codec = os.environ.get("SE_CODEC", "libx264")
        self.preset = os.environ.get("SE_PRESET", "-preset ultrafast")
        self.crf = os.environ.get("SE_VIDEO_CRF", "28")
        self.maxrate = os.environ.get("SE_VIDEO_MAXRATE", "1000k")
        self.bufsize = os.environ.get("SE_VIDEO_BUFSIZE", "2000k")
        self.ffmpeg_threads = os.environ.get("SE_FFMPEG_THREADS", "1")
        self.display_num = os.environ.get("DISPLAY_NUM", "99")
        self.display_container = os.environ.get("DISPLAY_CONTAINER_NAME", "selenium")
        self.record_audio = os.environ.get("SE_RECORD_AUDIO", "false").lower() == "true"
        self.audio_source = os.environ.get("SE_AUDIO_SOURCE", "")

        # Upload configuration (enabled when destination prefix is configured)
        self.upload_destination = os.environ.get("SE_UPLOAD_DESTINATION_PREFIX", "").strip()
        self.upload_enabled = bool(self.upload_destination)
        self.rclone_config = os.environ.get(
            "SE_RCLONE_CONFIG", os.environ.get("RCLONE_CONFIG", "/opt/selenium/upload.conf")
        )
        self.upload_command = os.environ.get("SE_UPLOAD_COMMAND", "copy")
        self.upload_opts = os.environ.get("SE_UPLOAD_OPTS", "-P --cutoff-mode SOFT --metadata --inplace")
        self.retain_local = os.environ.get("SE_UPLOAD_RETAIN_LOCAL_FILE", "false").lower() == "true"
        self.upload_batch_size = int(os.environ.get("SE_VIDEO_UPLOAD_BATCH_CHECK", "10"))
        self.upload_timeout = int(os.environ.get("SE_VIDEO_UPLOAD_TIMEOUT", "300"))
        self.retain_on_failure_enabled = os.environ.get("SE_RETAIN_ON_FAILURE", "false").lower() == "true"
        default_failure_events = [":failure", ":failed", ":error", ":aborted"]
        custom_failure_events = os.environ.get("SE_FAILURE_SESSION_EVENTS", "").lower()
        custom_failure_events_list = []
        if custom_failure_events:
            custom_failure_events_list = [event.strip() for event in custom_failure_events.split(",") if event.strip()]
        self.failure_events = list(dict.fromkeys(default_failure_events + custom_failure_events_list))

        # Capability names
        self.video_cap_name = os.environ.get("VIDEO_CAP_NAME", "se:recordVideo")
        # Default recording state used when the se:recordVideo capability is absent
        # on a session. Mirrors the fallback in the shell-mode helper (video_nodeQuery.py)
        # so SE_RECORD_VIDEO=false is honored across both recording modes.
        self.default_record_video = os.environ.get("SE_RECORD_VIDEO", "true").lower() != "false"
        self.test_name_cap = os.environ.get("TEST_NAME_CAP", "se:name")
        self.video_name_cap = os.environ.get("VIDEO_NAME_CAP", "se:videoName")
        self.file_name_trim_regex = os.environ.get("SE_VIDEO_FILE_NAME_TRIM_REGEX", "[^a-zA-Z0-9-_]")
        self.file_name_suffix = os.environ.get("SE_VIDEO_FILE_NAME_SUFFIX", "true").lower() == "true"
        configured_video_file_name = os.environ.get("FILE_NAME", os.environ.get("SE_VIDEO_FILE_NAME", "auto")).strip()
        self.configured_video_file_name = configured_video_file_name if configured_video_file_name else "auto"

        # Standalone mode: single node, no need to filter events by NodeId
        self.record_standalone = os.environ.get("SE_VIDEO_RECORD_STANDALONE", "false").lower() == "true"

        # Subfolder mode: save each session's video inside VIDEO_FOLDER/{session_id}/
        self.session_subfolder = os.environ.get("SE_VIDEO_SESSION_SUBFOLDER", "false").lower() == "true"

        # Node identity for filtering events in distributed (Hub-Nodes) setup.
        # In distributed mode, ZeroMQ broadcasts ALL session events to ALL subscribers.
        # Each Node's recorder must filter to only process events for its own Node.
        # Node ID is resolved from the Node /status endpoint on startup.
        # In standalone mode, NodeId filtering is skipped since there is only one node.
        self.node_id: Optional[str] = None
        self.node_external_uri: Optional[str] = None

        # Node /status endpoint configuration
        self.se_server_protocol = os.environ.get("SE_SERVER_PROTOCOL", "http")
        default_node_port = "4444" if self.record_standalone else "5555"
        self.se_node_port = os.environ.get("SE_NODE_PORT", default_node_port)
        self.node_status_verify_ssl = False
        self.node_poll_interval = int(os.environ.get("SE_VIDEO_POLL_INTERVAL", "2"))
        self.file_ready_max_attempts = int(os.environ.get("SE_VIDEO_FILE_READY_WAIT_ATTEMPTS", "10"))

        # Drain configuration
        self.max_sessions = int(os.environ.get("SE_DRAIN_AFTER_SESSION_COUNT", "0"))
        self.recorded_count = 0

        # Force move command if not retaining local files
        if not self.retain_local:
            self.upload_command = "move"

        # Session state management - single source of truth
        self.sessions: Dict[str, SessionState] = {}
        self.sessions_lock = asyncio.Lock()

        # Upload queue - internal communication between recorder and uploader
        self.upload_queue: asyncio.Queue[UploadTask] = asyncio.Queue()

        # Active upload processes
        self.active_uploads: List[asyncio.subprocess.Process] = []

        # ZMQ resources
        self.context: Optional[zmq.asyncio.Context] = None
        self.subscriber: Optional[zmq.asyncio.Socket] = None

        # Shutdown coordination
        self.shutdown_event = asyncio.Event()
        self.recorder_done = asyncio.Event()
        self.uploader_done = asyncio.Event()

        # Tracked delayed-cleanup tasks so they can be cancelled on shutdown
        self._cleanup_tasks: List[asyncio.Task] = []

        # Rename SE_RCLONE_* env vars
        self._rename_rclone_env()

    def _rename_rclone_env(self):
        """Rename SE_RCLONE_* environment variables to RCLONE_*."""
        for var in list(os.environ.keys()):
            if var.startswith("SE_RCLONE_"):
                suffix = var[len("SE_RCLONE_") :]
                new_var = f"RCLONE_{suffix}"
                os.environ[new_var] = os.environ[var]

    @property
    def display(self) -> str:
        return f"{self.display_container}:{self.display_num}.0"

    @property
    def video_size(self) -> str:
        return f"{self.screen_width}x{self.screen_height}"

    def normalize_filename(self, filename: str) -> str:
        """Normalize filename by removing disallowed characters."""
        if not filename:
            return ""
        normalized = filename.replace(" ", "_")
        try:
            pattern = re.compile(self.file_name_trim_regex)
        except re.error:
            pattern = re.compile("[^a-zA-Z0-9-_]")
        normalized = re.sub(pattern, "", normalized)
        return normalized[:251]

    def get_video_filename(self, session_id: str, capabilities: dict) -> tuple[bool, str]:
        """Determine video filename from session capabilities.

        Recording is gated by the se:recordVideo capability when it is present on
        the session; when the capability is absent, it falls back to the
        SE_RECORD_VIDEO environment default. This keeps the event-driven service
        consistent with the shell-mode helper (video_nodeQuery.py).
        """
        record_video = capabilities.get(self.video_cap_name)
        if record_video is None:
            record_video = self.default_record_video
        elif isinstance(record_video, str):
            record_video = record_video.lower() != "false"
        else:
            record_video = bool(record_video)

        if self.configured_video_file_name.lower() != "auto":
            fixed_name = self.configured_video_file_name
            fixed_path = Path(self.video_folder) / fixed_name
            if fixed_path.exists():
                logger.warning(
                    "Configured video file %r already exists in %s and may be overwritten",
                    fixed_name,
                    self.video_folder,
                )
            return record_video, fixed_name

        video_name = capabilities.get(self.video_name_cap)
        test_name = capabilities.get(self.test_name_cap)

        if video_name and video_name != "null":
            name = video_name
        elif test_name and test_name != "null":
            name = test_name
        else:
            name = ""

        if not name:
            name = session_id
        elif self.file_name_suffix:
            name = f"{name}_{session_id}"

        name = self.normalize_filename(name)
        return record_video, f"{name}.mp4"

    def is_failure_event_type(self, event_type: str) -> bool:
        """Check if event type indicates a failure."""
        event_lower = event_type.lower()
        return any(event in event_lower for event in self.failure_events)

    def is_own_node_event(self, data: dict) -> bool:
        """Check if an event belongs to this Node.

        In distributed Hub-Nodes setup, the ZeroMQ event bus broadcasts all
        session events to all subscribers. Each Node's recorder must filter
        to only process events for sessions on its own Node.

        Matching is done by comparing the event's nodeId against the Node ID
        obtained from the Node /status endpoint on startup.

        In standalone mode, all events belong to this Node, so filtering is skipped.
        """
        if self.record_standalone:
            return True

        if self.node_id is None:
            # Node ID not yet resolved, cannot filter
            logger.warning("Node ID not resolved yet, skipping event")
            return False

        event_node_id = data.get("nodeId", "")
        return event_node_id == self.node_id

    async def wait_for_node_ready(self) -> None:
        """Wait for the Node /status endpoint to be reachable and resolve Node ID.

        Polls the Node /status endpoint until it returns HTTP 200,
        then extracts nodeId and externalUri from the response.

        Response structure differs by mode:
        - Standalone (hub): $.value.nodes[0].id, $.value.nodes[0].externalUri
        - Distributed (node): $.value.node.nodeId, $.value.node.externalUri
        - Standalone sidecar on dynamic grid node: falls back to $.value.node path
        """
        node_status_url = f"{self.se_server_protocol}://{self.display_container}:{self.se_node_port}/status"
        headers = {}
        if self.registration_secret:
            headers["X-REGISTRATION-SECRET"] = self.registration_secret
        if self.router_username and self.router_password:
            auth_token = base64.b64encode(f"{self.router_username}:{self.router_password}".encode("utf-8")).decode(
                "utf-8"
            )
            headers["Authorization"] = f"Basic {auth_token}"
            logger.info("Using Basic Auth for Node /status endpoint")
        elif self.router_username or self.router_password:
            logger.warning("Partial SE_ROUTER credentials provided; skipping Basic Auth for Node /status endpoint")

        ssl_context = None
        if self.se_server_protocol.lower() == "https" and not self.node_status_verify_ssl:
            ssl_context = ssl._create_unverified_context()

        logger.info(
            f"Waiting for Node /status endpoint: {node_status_url} " f"(verify_ssl={self.node_status_verify_ssl})"
        )

        def _fetch_status() -> Optional[dict]:
            """Blocking HTTP fetch run in a thread to avoid blocking the event loop."""
            req = Request(node_status_url, headers=headers)
            try:
                if ssl_context is not None:
                    resp_ctx = urlopen(req, timeout=5, context=ssl_context)
                else:
                    resp_ctx = urlopen(req, timeout=5)
                with resp_ctx as resp:
                    if resp.status == 200:
                        return json.loads(resp.read().decode("utf-8"))
            except (URLError, OSError, json.JSONDecodeError, ValueError):
                pass
            return None

        while not self.shutdown_event.is_set():
            try:
                # Run blocking urlopen in a thread so SIGTERM can be processed
                # immediately by the event loop without waiting up to 5s.
                body = await asyncio.to_thread(_fetch_status)
                if body is not None:
                    if self.record_standalone:
                        nodes = body.get("value", {}).get("nodes", [])
                        if nodes:
                            node_info = nodes[0]
                            self.node_id = node_info.get("id")
                            self.node_external_uri = node_info.get("externalUri")
                        else:
                            # Fallback: sidecar connected directly to a node
                            # (e.g. dynamic grid where /status returns singular "node")
                            node_info = body.get("value", {}).get("node", {})
                            self.node_id = node_info.get("nodeId") or node_info.get("id")
                            self.node_external_uri = node_info.get("externalUri")
                    else:
                        node_info = body.get("value", {}).get("node", {})
                        self.node_id = node_info.get("nodeId")
                        self.node_external_uri = node_info.get("externalUri")

                    if self.node_id:
                        logger.info(f"Node is ready. ID: {self.node_id}, URI: {self.node_external_uri}")
                        return
                    else:
                        logger.warning("Node /status responded but nodeId is missing, retrying...")
                else:
                    logger.debug(f"Node not ready yet: {node_status_url}")
            except Exception as e:
                logger.warning(f"Unexpected error polling Node /status: {e}")

            try:
                await asyncio.wait_for(self.shutdown_event.wait(), timeout=self.node_poll_interval)
            except asyncio.TimeoutError:
                pass

    # ==================== Recording Functions ====================

    async def start_recording(self, session: SessionState) -> bool:
        """Start ffmpeg recording for a session."""
        if session.ffmpeg_process is not None:
            logger.warning(f"Recording already in progress for session {session.session_id}")
            return False

        video_path = f"{self.video_folder}/{session.video_file}"
        session.start_time = datetime.now()
        session.status = SessionStatus.RECORDING

        cmd = [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "warning",
            "-threads",
            self.ffmpeg_threads,
            "-thread_queue_size",
            "512",
            "-probesize",
            "32M",
            "-analyzeduration",
            "0",
            "-y",
            "-f",
            "x11grab",
            "-video_size",
            self.video_size,
            "-r",
            self.frame_rate,
            "-i",
            self.display,
        ]

        if self.record_audio and self.audio_source:
            cmd.extend(self.audio_source.split())

        cmd.extend(
            [
                "-codec:v",
                self.codec,
                *self.preset.split(),
                "-tune",
                "zerolatency",
                "-crf",
                self.crf,
                "-maxrate",
                self.maxrate,
                "-bufsize",
                self.bufsize,
                "-pix_fmt",
                "yuv420p",
                "-movflags",
                "frag_keyframe+empty_moov+default_base_moof",
                video_path,
            ]
        )

        try:
            env = os.environ.copy()
            env["DISPLAY"] = self.display
            session.ffmpeg_process = await asyncio.create_subprocess_exec(
                *cmd,
                env=env,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.PIPE,
            )
            # Give ffmpeg a moment to fail fast (bad codec, missing display, etc.)
            await asyncio.sleep(0.5)
            if session.ffmpeg_process.returncode is not None:
                stderr_output = await session.ffmpeg_process.stderr.read()
                logger.error(
                    f"ffmpeg exited immediately for {session.session_id} "
                    f"(rc={session.ffmpeg_process.returncode}): {stderr_output.decode(errors='replace').strip()}"
                )
                session.ffmpeg_process = None
                session.status = SessionStatus.CREATED
                return False
            logger.info(f"Started recording: session={session.session_id}, file={session.video_file}")
            return True
        except Exception as e:
            logger.error(f"Failed to start recording for {session.session_id}: {e}")
            session.status = SessionStatus.CREATED
            return False

    async def wait_for_file_integrity(self, video_path: Path) -> bool:
        """Wait for a recorded video to become readable by ffmpeg."""
        if not video_path.exists():
            logger.warning(f"Video file not found after recording stopped: {video_path}")
            return False

        for attempt in range(1, self.file_ready_max_attempts + 1):
            proc = await asyncio.create_subprocess_exec(
                "ffmpeg",
                "-v",
                "error",
                "-i",
                str(video_path),
                "-f",
                "null",
                "-",
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.PIPE,
            )
            _, stderr_bytes = await proc.communicate()
            if proc.returncode == 0:
                return True

            stderr_text = stderr_bytes.decode(errors="replace").strip()
            if attempt >= self.file_ready_max_attempts:
                logger.warning(
                    f"Recorded video is not readable after {attempt} attempts: {video_path}; "
                    f"ffmpeg probe stderr={stderr_text}"
                )
                return False

            logger.info(
                f"Waiting for recorded video to become readable: {video_path} "
                f"(attempt {attempt}/{self.file_ready_max_attempts})"
            )
            await asyncio.sleep(self.node_poll_interval)

        return False

    async def stop_recording(self, session: SessionState) -> bool:
        """Stop ffmpeg recording for a session."""
        # Claim the process atomically before the first await.  Asyncio is
        # cooperative: no other coroutine can run between the check and the
        # assignment, so a concurrent caller (e.g. cleanup() racing with
        # handle_session_closed()) will see None here and return early,
        # preventing double-terminate and double-upload.
        proc = session.ffmpeg_process
        if proc is None:
            return False
        session.ffmpeg_process = None

        # Only move to STOPPING if we are still in the RECORDING state.
        # handle_session_closed() sets status to CLOSED before calling us;
        # overwriting that with STOPPING would prevent _cleanup_session_delayed
        # from ever cleaning up the session (it checks status == CLOSED).
        if session.status == SessionStatus.RECORDING:
            session.status = SessionStatus.STOPPING
        session.end_time = datetime.now()

        try:
            try:
                graceful_stop_sent = False
                if proc.stdin is not None and not proc.stdin.is_closing():
                    try:
                        proc.stdin.write(b"q\n")
                        await proc.stdin.drain()
                        proc.stdin.close()
                        graceful_stop_sent = True
                    except (BrokenPipeError, ConnectionResetError):
                        pass

                _, stderr_bytes = await asyncio.wait_for(proc.communicate(), timeout=10.0)
            except asyncio.TimeoutError:
                if graceful_stop_sent:
                    logger.warning(f"ffmpeg did not stop after quit command for {session.session_id}, terminating")
                else:
                    logger.warning(f"ffmpeg stdin unavailable for {session.session_id}, terminating")

                proc.terminate()
                try:
                    _, stderr_bytes = await asyncio.wait_for(proc.communicate(), timeout=5.0)
                except asyncio.TimeoutError:
                    logger.warning(f"ffmpeg did not stop gracefully for {session.session_id}, killing")
                    proc.kill()
                    _, stderr_bytes = await proc.communicate()

            rc = proc.returncode
            if stderr_bytes:
                stderr_text = stderr_bytes.decode(errors="replace").strip()
                if stderr_text:
                    logger.warning(f"ffmpeg stderr for {session.session_id}: {stderr_text}")

            # 255 is ffmpeg's own graceful-stop exit code (exit_program(255) in its SIGTERM handler).
            if rc not in (0, 255, -signal.SIGTERM, -signal.SIGKILL):
                logger.error(f"ffmpeg exited with unexpected code {rc} for {session.session_id}")
                session.status = SessionStatus.CLOSED
                return False

            if session.video_file:
                video_path = Path(self.video_folder) / session.video_file
                if not await self.wait_for_file_integrity(video_path):
                    session.status = SessionStatus.CLOSED
                    return False

            self.recorded_count += 1
            session.status = SessionStatus.CLOSED
            duration = session.duration_seconds
            logger.info(
                f"Stopped recording: session={session.session_id}, " f"duration={duration:.1f}s"
                if duration
                else f"Stopped recording: session={session.session_id}"
            )
            return True
        except Exception as e:
            logger.error(f"Failed to stop recording for {session.session_id}: {e}")
            session.status = SessionStatus.CLOSED
            return False

    # ==================== Upload Functions ====================

    async def queue_upload(self, session: SessionState) -> None:
        """Queue a video for upload based on configuration."""
        if not self.upload_enabled or not self.upload_destination:
            return

        if not session.video_file:
            return

        video_path = f"{self.video_folder}/{session.video_file}"
        if not Path(video_path).exists():
            logger.warning(f"Video file not found: {video_path}")
            return

        task = UploadTask(
            session_id=session.session_id,
            video_file=video_path,
            destination=self.upload_destination,
        )

        await self.upload_queue.put(task)
        logger.debug(f"Queued upload task: {session.session_id}")

    async def process_upload(self, task: UploadTask) -> None:
        """Process a single upload task."""
        logger.info(f"Uploading: {task.video_file} -> {task.destination}")

        cmd = [
            "rclone",
            "--config",
            self.rclone_config,
            self.upload_command,
            *self.upload_opts.split(),
            task.video_file,
            task.destination,
        ]

        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            self.active_uploads.append(proc)
            try:
                try:
                    stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=self.upload_timeout)
                except asyncio.TimeoutError:
                    logger.warning(f"Upload timed out after {self.upload_timeout}s: {task.video_file}, killing process")
                    proc.kill()
                    _, stderr_bytes = await proc.communicate()
                    if stderr_bytes:
                        logger.debug(
                            f"Upload stderr at timeout for {task.video_file}: "
                            f"{stderr_bytes.decode(errors='replace').strip()}"
                        )
                    return
            finally:
                try:
                    self.active_uploads.remove(proc)
                except ValueError:
                    pass

            if proc.returncode == 0:
                logger.info(f"Upload complete: {task.video_file}")
            else:
                logger.error(f"Upload failed: {task.video_file}, stderr={stderr.decode()}")

        except Exception as e:
            logger.error(f"Upload error: {task.video_file}, error={e}")

    async def upload_worker(self) -> None:
        """Background worker that processes upload queue."""
        logger.info("Upload worker started")
        active_tasks: List[asyncio.Task] = []

        try:
            while True:
                try:
                    # Block until an item is available (or cancelled)
                    task = await self.upload_queue.get()
                except asyncio.CancelledError:
                    logger.warning("Upload worker cancelled, pending uploads may be lost")
                    for t in active_tasks:
                        t.cancel()
                    # Await cancelled tasks so they are not left as orphaned
                    # asyncio tasks (which causes "Task destroyed but pending" warnings
                    # and makes the active_uploads kill loop in run() the sole cleanup).
                    await asyncio.gather(*active_tasks, return_exceptions=True)
                    raise

                # None is the sentinel pushed by cleanup() to signal no more uploads
                if task is None:
                    break

                try:
                    # Process upload (could run multiple in parallel up to batch_size)
                    upload_task = asyncio.create_task(self.process_upload(task))
                    active_tasks.append(upload_task)

                    # Clean up completed tasks
                    active_tasks = [t for t in active_tasks if not t.done()]

                    # Wait if we've hit batch limit
                    if len(active_tasks) >= self.upload_batch_size:
                        done, pending = await asyncio.wait(active_tasks, return_when=asyncio.FIRST_COMPLETED)
                        active_tasks = list(pending)
                except Exception as e:
                    logger.error(f"Upload worker error: {e}")

            # Drain all in-flight uploads before exiting
            if active_tasks:
                logger.info(f"Waiting for {len(active_tasks)} pending uploads...")
                await asyncio.gather(*active_tasks, return_exceptions=True)

        finally:
            self.uploader_done.set()
            logger.info("Upload worker stopped")

    # ==================== Event Handlers ====================

    async def handle_session_created(self, data: dict) -> None:
        """Handle session-created event."""
        session_id = data.get("sessionId")
        if not session_id:
            logger.warning("Received session-created without sessionId")
            return

        # Filter: only process sessions belonging to this Node
        if not self.is_own_node_event(data):
            event_node_id = data.get("nodeId", "unknown")
            return

        capabilities = data.get("capabilities", {})
        record_video, video_filename = self.get_video_filename(session_id, capabilities)

        if record_video and self.session_subfolder:
            session_subdir = Path(self.video_folder) / session_id
            session_subdir.mkdir(parents=True, exist_ok=True)
            video_filename = f"{session_id}/{video_filename}"
            logger.info(f"Created session subfolder: {session_subdir}")

        retain_on_failure_cap = capabilities.get("se:retainOnFailure", None)
        if retain_on_failure_cap is None:
            retain_on_failure = self.retain_on_failure_enabled
        else:
            retain_on_failure = str(retain_on_failure_cap).lower() == "true"

        async with self.sessions_lock:
            session = SessionState(
                session_id=session_id,
                capabilities=capabilities,
                video_file=video_filename,
                record_video=record_video,
                retain_on_failure=retain_on_failure,
                test_name=capabilities.get(self.test_name_cap, ""),
            )
            self.sessions[session_id] = session

        logger.info(
            f"Session created: {session_id}, record={record_video}, "
            f"retain_on_failure={retain_on_failure}, file={video_filename}"
        )

        if record_video:
            await self.start_recording(session)

    async def handle_session_closed(self, data: dict) -> None:
        """Handle session-closed event."""
        session_id = data.get("sessionId")
        if not session_id:
            logger.warning("Received session-closed without sessionId")
            return

        # Filter: only process sessions belonging to this Node
        if not self.is_own_node_event(data):
            event_node_id = data.get("nodeId", "unknown")
            return

        reason_str = data.get("reason", "QUIT_COMMAND")
        try:
            reason = SessionClosedReason(reason_str)
        except ValueError:
            reason = SessionClosedReason.QUIT_COMMAND

        async with self.sessions_lock:
            session = self.sessions.get(session_id)
            if session is None:
                logger.warning(f"Session-closed for unknown session: {session_id}")
                return

            session.close_reason = reason
            session.status = SessionStatus.CLOSED

        logger.info(f"Session closed: {session_id}, reason={reason.value}, is_failed={session.is_failed}")

        # Stop recording if in progress
        if session.ffmpeg_process is not None:
            stopped = await self.stop_recording(session)
            if stopped:
                discard = session.retain_on_failure and not session.is_failed
                if discard:
                    if session.video_file:
                        video_path = Path(self.video_folder) / session.video_file
                        if video_path.exists():
                            try:
                                video_path.unlink()
                                logger.info(f"Video discarded for successful session {session_id} (retain-on-failure)")
                            except Exception as exc:
                                logger.warning(f"Failed to delete video file {video_path}: {exc}")
                else:
                    await self.queue_upload(session)
            else:
                logger.warning(f"Recording stop failed for {session_id}, skipping upload")

        # Clean up session after a delay (keep for potential late events).
        # Tracked so cleanup() can cancel these on shutdown instead of waiting 60s.
        t = asyncio.create_task(self._cleanup_session_delayed(session_id, delay=60))
        self._cleanup_tasks.append(t)
        t.add_done_callback(lambda fut: self._cleanup_tasks.remove(fut) if fut in self._cleanup_tasks else None)

        # Check drain condition
        if self.max_sessions > 0 and self.recorded_count >= self.max_sessions:
            logger.info(f"Max sessions reached ({self.max_sessions}), initiating shutdown")
            self.shutdown_event.set()

    async def handle_session_event(self, data: dict) -> None:
        """Handle custom session-event."""
        session_id = data.get("sessionId")
        event_type = data.get("eventType", "")
        payload = data.get("payload", {})

        if not session_id:
            logger.warning("Received session-event without sessionId")
            return

        # Filter: only process sessions belonging to this Node
        if not self.is_own_node_event(data):
            event_node_id = data.get("nodeId", "unknown")
            return

        async with self.sessions_lock:
            session = self.sessions.get(session_id)
            if session is None:
                # Create placeholder for late-arriving events
                session = SessionState(session_id=session_id)
                self.sessions[session_id] = session

            if self.is_failure_event_type(event_type):
                session.has_failure_event = True
                session.failure_events.append(event_type)
                logger.info(f"Failure event: session={session_id}, type={event_type}")
            else:
                logger.debug(f"Session event: session={session_id}, type={event_type}")

    async def _cleanup_session_delayed(self, session_id: str, delay: float) -> None:
        """Remove session from tracking after delay."""
        await asyncio.sleep(delay)
        async with self.sessions_lock:
            if session_id in self.sessions:
                session = self.sessions[session_id]
                if session.status == SessionStatus.CLOSED:
                    del self.sessions[session_id]
                    logger.debug(f"Cleaned up session: {session_id}")

    # ==================== Event Bus ====================

    async def subscribe_events(self) -> None:
        """Subscribe to event bus and process events."""
        self.context = zmq.asyncio.Context()
        self.subscriber = self.context.socket(zmq.SUB)
        self.subscriber.setsockopt(zmq.LINGER, 0)

        # Configure connection and reconnection timings for better startup resilience.
        if hasattr(zmq, "CONNECT_TIMEOUT"):
            self.subscriber.setsockopt(zmq.CONNECT_TIMEOUT, self.event_bus_connect_timeout_ms)
        if hasattr(zmq, "RECONNECT_IVL"):
            self.subscriber.setsockopt(zmq.RECONNECT_IVL, self.event_bus_reconnect_interval_ms)
        if hasattr(zmq, "RECONNECT_IVL_MAX"):
            self.subscriber.setsockopt(zmq.RECONNECT_IVL_MAX, self.event_bus_reconnect_interval_max_ms)

        connection = f"tcp://{self.event_bus_host}:{self.event_bus_port}"
        logger.info(
            f"Connecting to event bus: {connection} "
            f"(connect_timeout_ms={self.event_bus_connect_timeout_ms}, "
            f"reconnect_ivl_ms={self.event_bus_reconnect_interval_ms}, "
            f"reconnect_ivl_max_ms={self.event_bus_reconnect_interval_max_ms})"
        )

        while not self.shutdown_event.is_set():
            try:
                self.subscriber.connect(connection)
                break
            except zmq.ZMQError as e:
                wait_seconds = max(0.1, self.event_bus_reconnect_interval_ms / 1000.0)
                logger.warning(f"Event bus connect failed: {e}; retrying in {wait_seconds:.1f}s")
                await asyncio.sleep(wait_seconds)

        if self.shutdown_event.is_set():
            return

        # Subscribe to session events
        for event in ["session-created", "session-closed", "session-event"]:
            self.subscriber.setsockopt_string(zmq.SUBSCRIBE, event)

        handlers = {
            "session-created": self.handle_session_created,
            "session-closed": self.handle_session_closed,
            "session-event": self.handle_session_event,
        }

        logger.info(f"Subscribed to events: {list(handlers.keys())}")

        try:
            while not self.shutdown_event.is_set():
                try:
                    if await self.subscriber.poll(timeout=1000):
                        frames = await self.subscriber.recv_multipart()

                        # Re-check shutdown before spending time processing the event
                        if self.shutdown_event.is_set():
                            break

                        if len(frames) < 4:
                            continue

                        event_name = frames[0].decode("utf-8")
                        secret = frames[1].decode("utf-8")
                        event_id = frames[2].decode("utf-8")
                        data_json = frames[3].decode("utf-8")

                        # Validate secret
                        if self.registration_secret:
                            try:
                                received = json.loads(secret)
                                if received != self.registration_secret:
                                    continue
                            except json.JSONDecodeError:
                                continue

                        # Parse and handle event
                        try:
                            data = json.loads(data_json)
                            event_node_id = data.get("nodeId", "N/A")
                            if self.record_standalone or (self.node_id is not None and event_node_id == self.node_id):
                                logger.info(
                                    f"Received event: {event_name}, "
                                    f"nodeId={event_node_id}, self.node_id={self.node_id}"
                                )
                            handler = handlers.get(event_name)
                            if handler:
                                await handler(data)
                        except json.JSONDecodeError as e:
                            logger.error(f"Failed to parse event data: {e}")

                except zmq.ZMQError as e:
                    if e.errno == zmq.ETERM:
                        break
                    logger.error(f"ZMQ error: {e}")
                    await asyncio.sleep(1)

        finally:
            self.recorder_done.set()
            if self.subscriber:
                self.subscriber.close()
            if self.context:
                self.context.term()

    # ==================== Lifecycle ====================

    async def wait_for_display(self) -> None:
        """Wait for X11 display to be available."""
        env = os.environ.copy()
        env["DISPLAY"] = self.display
        logger.info(f"Waiting for display: {self.display}")

        while not self.shutdown_event.is_set():
            try:
                proc = await asyncio.create_subprocess_exec(
                    "xset",
                    "b",
                    "off",
                    env=env,
                    stdout=asyncio.subprocess.DEVNULL,
                    stderr=asyncio.subprocess.DEVNULL,
                )
                await proc.wait()
                if proc.returncode == 0:
                    logger.info(f"Display ready: {self.display}")
                    return
            except Exception:
                pass
            try:
                await asyncio.wait_for(self.shutdown_event.wait(), timeout=2)
            except asyncio.TimeoutError:
                pass

    async def cleanup(self) -> None:
        """Cleanup all resources."""
        logger.info("Shutting down...")

        # Cancel delayed session-cleanup tasks immediately — they have a 60s
        # sleep that would keep the event loop alive long after shutdown.
        for t in list(self._cleanup_tasks):
            t.cancel()
        if self._cleanup_tasks:
            await asyncio.gather(*self._cleanup_tasks, return_exceptions=True)
        self._cleanup_tasks.clear()

        # Snapshot active sessions outside the lock so we don't hold
        # sessions_lock across slow awaits (stop_recording can take up to 10s).
        async with self.sessions_lock:
            active_sessions = [s for s in self.sessions.values() if s.ffmpeg_process is not None]

        for session in active_sessions:
            logger.info(f"Stopping recording: {session.session_id}")
            stopped = await self.stop_recording(session)
            if stopped:
                discard = session.retain_on_failure and not session.is_failed
                if not discard:
                    await self.queue_upload(session)
            else:
                logger.warning(f"Recording stop failed for {session.session_id}, skipping upload")

        # Push sentinel so the upload worker exits after draining the queue.
        # run() is responsible for awaiting the upload task with a timeout.
        await self.upload_queue.put(None)

        logger.info("Shutdown complete")

    async def run(self) -> None:
        """Main entry point."""
        logger.info("=" * 60)
        logger.info("Starting unified video recording and upload service")
        logger.info("=" * 60)
        logger.info(f"Configuration:")
        logger.info(f"  Standalone mode: {self.record_standalone}")
        logger.info(f"  Event bus: {self.event_bus_host}:{self.event_bus_port}")
        logger.info(f"  Video folder: {self.video_folder}")
        logger.info(f"  Session subfolder: {self.session_subfolder}")
        logger.info(f"  Video file name: {self.configured_video_file_name}")
        logger.info(f"  Video size: {self.video_size}")
        logger.info(f"  Upload enabled: {self.upload_enabled}")
        logger.info(f"  Upload destination: {self.upload_destination}")
        logger.info(f"  Retain on failure: {self.retain_on_failure_enabled}")
        logger.info(f"  Failure events: {self.failure_events}")
        logger.info(f"  Max sessions (drain): {self.max_sessions if self.max_sessions > 0 else 'unlimited'}")

        # Validate video folder
        if not Path(self.video_folder).is_dir():
            logger.error(f"Video folder does not exist: {self.video_folder}")
            return

        # Wait for display
        await self.wait_for_display()

        # Wait for Node /status endpoint and resolve Node ID
        await self.wait_for_node_ready()
        if self.node_id is None:
            logger.error("Failed to resolve Node ID from /status endpoint, exiting")
            return

        # Upload worker runs independently — it exits only when cleanup() pushes
        # a None sentinel, so it is NOT included in the gather below.
        upload_task = asyncio.create_task(self.upload_worker(), name="upload_worker")

        try:
            await asyncio.gather(
                asyncio.create_task(self.subscribe_events(), name="event_subscriber"),
            )
        except asyncio.CancelledError:
            logger.info("Tasks cancelled")
        finally:
            # cleanup() stops recordings, queues uploads, then pushes the sentinel.
            await self.cleanup()

            # Wait for the upload worker to drain and exit.
            try:
                await asyncio.wait_for(upload_task, timeout=30)
            except asyncio.TimeoutError:
                logger.warning("Upload worker did not finish in time, cancelling")
                upload_task.cancel()
                await asyncio.gather(upload_task, return_exceptions=True)

            # Kill any rclone processes still in flight
            for proc in self.active_uploads:
                try:
                    proc.kill()
                except Exception:
                    pass


async def main():
    """Main entry point."""
    service = VideoService()

    loop = asyncio.get_event_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, lambda: service.shutdown_event.set())

    try:
        await service.run()
    except KeyboardInterrupt:
        logger.info("Interrupted")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
