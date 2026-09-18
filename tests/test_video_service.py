"""Lifecycle regression tests; run with python -m unittest tests.test_video_service."""

import asyncio
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, Mock, patch

from Video import video_service as video


def event(session_id="one", **capabilities):
    """Build create data. Args: session_id: ID; capabilities: session options. Returns: Event dictionary."""
    return {"sessionId": session_id, "nodeId": "node", "capabilities": capabilities}


def status(*sessions, direct=False):
    """Build status. Args: sessions: slot sessions; direct: node format flag. Returns: Response dictionary."""
    node = {"id": "node", "slots": [{"session": session} for session in sessions] or [{"session": None}]}
    if direct:
        node["nodeId"] = node.pop("id")
    return {"value": {"node": node} if direct else {"nodes": [node]}}


class VideoServiceTests(unittest.IsolatedAsyncioTestCase):
    """Exercise recovery through the real handlers with controlled IO."""

    def setUp(self):
        """Create isolated service state. Args: None. Returns: None."""
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        environment = patch.dict(os.environ, {"VIDEO_FOLDER": directory.name}, clear=True)
        environment.start()
        self.addCleanup(environment.stop)
        self.service = video.VideoService()
        self.service.node_id = "node"
        self.service.upload_enabled = True
        self.service.upload_destination = "test:videos"
        self.service.subscriber = Mock(poll=AsyncMock(return_value=0))
        self.service._fetch_node_status = Mock(return_value=status())
        self.transitions = []
        self.service.start_recording = AsyncMock(side_effect=self.start)
        self.service.stop_recording = AsyncMock(side_effect=self.stop)

    async def asyncTearDown(self):
        """Cancel delayed state cleanup. Args: None. Returns: None."""
        tasks = list(self.service._cleanup_tasks)
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)

    async def start(self, session):
        """Model successful startup. Args: session: initialized state. Returns: True."""
        self.transitions.append(("start", session.session_id))
        session.status = video.SessionStatus.RECORDING
        session.ffmpeg_process = Mock()
        (Path(self.service.video_folder) / session.video_file).write_bytes(b"video")
        return True

    async def stop(self, session):
        """Model successful finalization. Args: session: recording state. Returns: True."""
        self.transitions.append(("stop", session.session_id))
        session.ffmpeg_process = None
        session.status = video.SessionStatus.CLOSED
        self.service.recorded_count += 1
        return True

    async def reconcile(self, payload):
        """Apply one snapshot. Args: payload: status response. Returns: None."""
        self.service._fetch_node_status.return_value = payload
        await self.service.reconcile_sessions()

    async def test_missed_events_and_duplicates_finalize_once(self):
        """Recover missing events without duplicate recording/upload. Args: None. Returns: None."""
        await self.reconcile(status(event()))
        original = self.service.sessions["one"]
        await self.reconcile(status(event()))
        await self.service.handle_session_created(event())
        await self.reconcile(status())
        self.assertEqual(original.status, video.SessionStatus.RECORDING)
        await self.reconcile(status())
        await self.service.handle_session_closed(event())
        self.assertIs(original, self.service.sessions["one"])
        self.assertEqual(self.transitions, [("start", "one"), ("stop", "one")])
        self.assertEqual(original.close_reason, video.SessionClosedReason.UNKNOWN)
        upload = self.service.upload_queue.get_nowait()
        self.assertEqual((upload.session_id, upload.destination), ("one", "test:videos"))
        self.assertTrue(self.service.upload_queue.empty())

    async def test_missing_recording_stops_before_replacement_starts(self):
        """Order rollover even when the old close is lost. Args: None. Returns: None."""
        self.service.configured_video_file_name = "shared.mp4"
        await self.reconcile(status(event("old")))
        await self.reconcile(status(event("new")))
        self.assertNotIn("new", self.service.sessions)
        await self.reconcile(status(event("new")))
        self.assertEqual(self.transitions, [("start", "old"), ("stop", "old"), ("start", "new")])
        queued = self.service.upload_queue.get_nowait()
        self.assertNotEqual(Path(queued.video_file).name, self.service.sessions["new"].video_file)
        self.assertEqual(Path(queued.video_file).read_bytes(), b"video")

    async def test_existing_and_concurrent_output_files_are_not_overwritten(self):
        """Protect saved and active fixed-name recordings. Args: None. Returns: None."""
        self.service.configured_video_file_name = "shared.mp4"
        original = Path(self.service.video_folder) / "shared.mp4"
        original.write_bytes(b"previous recording")
        await self.service.handle_session_created(event("one"))
        await self.service.handle_session_created(event("two"))
        names = {session.video_file for session in self.service.sessions.values()}
        self.assertEqual(len(names), 2)
        self.assertNotIn("shared.mp4", names)
        self.assertEqual(original.read_bytes(), b"previous recording")

    async def test_filename_and_subfolder_preserved_when_unique(self):
        """Keep configured naming for nonconflicting paths. Args: None. Returns: None."""
        self.service.configured_video_file_name = "video.mp4"
        self.service.session_subfolder = True
        await self.service.handle_session_created(event())
        self.assertEqual(self.service.sessions["one"].video_file, "one/video.mp4")

    async def test_uncertain_status_resets_consecutive_absence(self):
        """Never close on failed, incomplete, wrong-node or reserved status. Args: None. Returns: None."""
        malformed = [
            None,
            {},
            [],
            {"value": None},
            {"value": {"nodes": []}},
            {"value": {"nodes": [{"id": "other", "slots": []}]}},
            {"value": {"nodes": [{"id": "node"}]}},
            {"value": {"nodes": [{"id": "node", "slots": [{}]}]}},
            {"value": {"nodes": [{"id": "node", "slots": None}]}},
            status({}),
            status("reserved"),
            status(event("reserved")),
            status({"sessionId": "one", "capabilities": None}),
            status(event(), event()),
        ]
        await self.service.handle_session_created(event())
        for payload in malformed:
            with self.subTest(payload=payload):
                await self.reconcile(status())
                await self.reconcile(payload)
                self.assertFalse(self.service.missing_sessions)
                await self.reconcile(status())
                self.assertEqual(self.service.sessions["one"].status, video.SessionStatus.RECORDING)
                await self.reconcile(status(event()))
        self.service.stop_recording.assert_not_awaited()

    async def test_direct_node_status_and_node_filtering(self):
        """Support direct nodes without adopting another node's events. Args: None. Returns: None."""
        await self.reconcile(status(event(), direct=True))
        self.assertIn("one", self.service.sessions)
        await self.service.handle_session_created(dict(event("other"), nodeId="foreign"))
        await self.service.handle_session_closed(dict(event(), nodeId="foreign"))
        self.assertNotIn("other", self.service.sessions)
        self.assertFalse(self.service.closed_session_ids)

    async def test_closed_session_cannot_return_after_cleanup_or_absent_status(self):
        """Retain closure knowledge across cleanup and stale snapshots. Args: None. Returns: None."""
        await self.service.handle_session_created(event())
        await self.service.handle_session_closed(event())
        await self.service._cleanup_session_delayed("one", 0)
        self.assertNotIn("one", self.service.sessions)
        await self.reconcile(status())
        await self.reconcile(status(event()))
        await self.service.handle_session_created(event())
        await self.service.handle_session_event(dict(event(), eventType="test:failed"))
        self.assertNotIn("one", self.service.sessions)
        self.assertEqual(self.service.start_recording.await_count, 1)

    async def test_close_before_create_blocks_late_recovery(self):
        """Remember closes even when the create was never seen. Args: None. Returns: None."""
        await self.service.handle_session_closed(event())
        await self.reconcile(status(event()))
        await self.service.handle_session_created(event())
        self.service.start_recording.assert_not_awaited()

    async def test_failure_placeholder_and_disabled_recording_are_preserved(self):
        """Keep early failures and honor per-session recording opt-out. Args: None. Returns: None."""
        await self.service.handle_session_event(dict(event(), eventType="test:failed"))
        placeholder = self.service.sessions["one"]
        await self.reconcile(status(event(**{"se:retainOnFailure": True})))
        self.assertIs(placeholder, self.service.sessions["one"])
        self.assertEqual(placeholder.failure_events, ["test:failed"])
        await self.service.handle_session_closed(event())
        self.assertEqual(self.service.upload_queue.qsize(), 1)
        disabled = event("disabled", **{"se:recordVideo": False})
        await self.service.handle_session_created(disabled)
        await self.reconcile(status(disabled))
        self.assertEqual(self.service.start_recording.await_count, 1)

    async def test_failed_ffmpeg_start_retries_without_replacing_state(self):
        """Exercise actual startup failure paths and successful retry. Args: None. Returns: None."""
        self.service.start_recording = video.VideoService.start_recording.__get__(self.service)
        failed = Mock(returncode=1, stderr=Mock(read=AsyncMock(return_value=b"display unavailable")))
        healthy = Mock(returncode=None)
        with patch.object(video.asyncio, "create_subprocess_exec", AsyncMock(side_effect=[OSError(), failed, healthy])):
            await self.service.handle_session_created(event())
            original = self.service.sessions["one"]
            filename = original.video_file
            await self.reconcile(status(event()))
            self.assertEqual(original.status, video.SessionStatus.CREATED)
            await self.reconcile(status(event()))
            self.assertIs(self.service.sessions["one"], original)
            self.assertEqual(original.video_file, filename)
            self.assertIs(original.ffmpeg_process, healthy)
            await self.service.handle_session_created(event())

    async def test_unknown_close_keeps_retain_on_failure_video(self):
        """An inferred close cannot establish test success. Args: None. Returns: None."""
        await self.reconcile(status(event(**{"se:retainOnFailure": True})))
        await self.reconcile(status())
        await self.reconcile(status())
        self.assertEqual(self.service.upload_queue.qsize(), 1)

    async def test_explicit_success_still_discards_retain_on_failure_video(self):
        """Preserve the established retain-on-failure success behavior. Args: None. Returns: None."""
        await self.service.handle_session_created(event(**{"se:retainOnFailure": True}))
        filename = self.service.sessions["one"].video_file
        await self.service.handle_session_closed(dict(event(), reason="QUIT_COMMAND"))
        self.assertFalse((Path(self.service.video_folder) / filename).exists())
        self.assertTrue(self.service.upload_queue.empty())

    async def test_shutdown_keeps_unfinished_retain_on_failure_recording(self):
        """Do not assume an unfinished session passed. Args: None. Returns: None."""
        await self.service.handle_session_created(event(**{"se:retainOnFailure": True}))
        await self.service.cleanup()
        self.assertEqual(self.service.upload_queue.get_nowait().session_id, "one")
        self.assertIsNone(self.service.upload_queue.get_nowait())

    async def test_unknown_event_reason_keeps_retain_on_failure_recording(self):
        """Do not interpret an unrecognized close reason as success. Args: None. Returns: None."""
        await self.service.handle_session_created(event(**{"se:retainOnFailure": True}))
        await self.service.handle_session_closed(dict(event(), reason="FUTURE_REASON"))
        self.assertEqual(self.service.upload_queue.qsize(), 1)

    async def test_event_queued_during_fetch_invalidates_snapshot(self):
        """Give newer bus events priority over sampled status. Args: None. Returns: None."""
        await self.service.handle_session_created(event())
        await self.reconcile(status())
        self.service.subscriber.poll.return_value = 1
        await self.reconcile(status(event("new")))
        self.assertFalse(self.service.missing_sessions)
        self.assertNotIn("new", self.service.sessions)
        self.service.stop_recording.assert_not_awaited()

    async def test_close_queued_during_finalization_prevents_stale_start(self):
        """Recheck queued events after slow finalization. Args: None. Returns: None."""
        await self.reconcile(status(event()))
        await self.reconcile(status(event("new")))
        self.service.subscriber.poll.side_effect = [0, 0, 1]
        await self.reconcile(status(event("new")))
        self.assertNotIn("new", self.service.sessions)
        self.assertEqual(self.service.upload_queue.qsize(), 1)

    async def test_late_create_resets_previous_missing_observation(self):
        """Do not combine an old negative with a newer create. Args: None. Returns: None."""
        await self.service.handle_session_created(event())
        await self.reconcile(status())
        await self.service.handle_session_created(event())
        await self.reconcile(status())
        self.service.stop_recording.assert_not_awaited()
        await self.reconcile(status())
        self.service.stop_recording.assert_awaited_once()

    async def test_queued_event_interrupts_multiple_inferred_closes(self):
        """Do not apply remaining stale closes after slow finalization. Args: None. Returns: None."""
        await self.reconcile(status(event("one"), event("two")))
        await self.reconcile(status())
        self.service.subscriber.poll.side_effect = [0, 0, 1]
        await self.reconcile(status())
        self.assertEqual(self.service.sessions["one"].status, video.SessionStatus.CLOSED)
        self.assertEqual(self.service.sessions["two"].status, video.SessionStatus.RECORDING)
        self.assertFalse(self.service.missing_sessions)

    async def test_shutdown_during_fetch_does_not_start_recording(self):
        """Reject a snapshot returned after shutdown. Args: None. Returns: None."""
        entered, release = asyncio.Event(), asyncio.Event()

        async def fetch(function):
            """Pause the fetch. Args: function: blocking fetch. Returns: Active status."""
            entered.set()
            await release.wait()
            return status(event())

        with patch.object(video.asyncio, "to_thread", side_effect=fetch):
            task = asyncio.create_task(self.service.reconcile_sessions())
            await entered.wait()
            self.service.shutdown_event.set()
            release.set()
            await task
        self.service.start_recording.assert_not_awaited()

    async def test_shutdown_finishes_in_flight_finalization_and_queues_once(self):
        """Drive the actual subscriber loop through shutdown mid-close. Args: None. Returns: None."""
        await self.service.handle_session_created(event())
        await self.reconcile(status())
        entered, release = asyncio.Event(), asyncio.Event()

        async def finish(session):
            """Pause after claiming ffmpeg. Args: session: closing state. Returns: True."""
            session.ffmpeg_process = None
            entered.set()
            await release.wait()
            return await self.stop(session)

        self.service.stop_recording.side_effect = finish
        context = Mock()
        context.socket.return_value = self.service.subscriber
        with patch.object(video.zmq.asyncio, "Context", return_value=context):
            task = asyncio.create_task(self.service.subscribe_events())
            await asyncio.wait_for(entered.wait(), 2)
            self.service.shutdown_event.set()
            self.assertFalse(task.done())
            release.set()
            await asyncio.wait_for(task, 2)
        await self.service.cleanup()
        self.assertEqual(self.service.upload_queue.get_nowait().session_id, "one")
        self.assertIsNone(self.service.upload_queue.get_nowait())
        self.assertTrue(self.service.upload_queue.empty())
        self.service.subscriber.close.assert_called_once()
        context.term.assert_called_once()

    def test_status_fetch_preserves_authentication_and_ssl_settings(self):
        """Use the same authenticated fetch for readiness and recovery. Args: None. Returns: None."""
        self.service._fetch_node_status = video.VideoService._fetch_node_status.__get__(self.service)
        self.service.registration_secret = "secret"
        self.service.router_username = "user"
        self.service.router_password = "pass"
        self.service.se_server_protocol = "https"
        response = Mock(status=200, read=Mock(return_value=json.dumps(status()).encode()))
        with patch.object(video, "urlopen") as request:
            request.return_value.__enter__.return_value = response
            self.assertEqual(self.service._fetch_node_status(), status())
            args, kwargs = request.call_args
            self.assertEqual(args[0].get_header("X-registration-secret"), "secret")
            self.assertEqual(args[0].get_header("Authorization"), "Basic dXNlcjpwYXNz")
            self.assertEqual(kwargs["timeout"], 5)
            self.assertIsNotNone(kwargs["context"])
            request.side_effect = OSError("unavailable")
            self.assertIsNone(self.service._fetch_node_status())


if __name__ == "__main__":
    unittest.main()
