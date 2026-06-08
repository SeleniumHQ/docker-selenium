#!/usr/bin/env python3

from __future__ import annotations

import base64
import json
import os
import string
import subprocess
import sys
import time
import urllib.error
import urllib.request
from typing import Tuple

from video_gridUrl import get_grid_url

MAX_TIME_SECONDS = 1
RETRY_TIME = 3


def get_graphql_endpoint() -> str:
    """Derive the GraphQL endpoint from env or helper script.

    If SE_NODE_GRID_GRAPHQL_URL is set, use it. Otherwise run /opt/bin/video_gridUrl.py
    (same as the bash script). Append '/graphql' if missing and non-empty.
    """
    endpoint = os.getenv("SE_NODE_GRID_GRAPHQL_URL")
    if not endpoint:
        endpoint = get_grid_url()
    if endpoint and not endpoint.endswith("/graphql"):
        endpoint = f"{endpoint}/graphql"
    return endpoint


def build_basic_auth_header() -> str | None:
    username = os.getenv("SE_ROUTER_USERNAME")
    password = os.getenv("SE_ROUTER_PASSWORD")
    if username and password:
        token = base64.b64encode(f"{username}:{password}".encode()).decode()
        return f"Authorization: Basic {token}"
    return None


def poll_session(endpoint: str, session_id: str, poll_interval: float) -> dict | None:
    """Poll the GraphQL endpoint for the session.

    Returns full parsed response dict if any request succeeded (HTTP 200) else None.
    Saves last successful body to /tmp/graphQL_<session_id>.json (for parity).
    """
    if not endpoint:
        return None

    query_obj = {
        "query": (
            f"{{ session (id: \"{session_id}\") {{ id, capabilities, startTime, uri, nodeId, nodeUri, "
            "sessionDurationMillis, slot { id, stereotype, lastStarted } }} }} "
        )
    }
    headers = {
        "Content-Type": "application/json",
    }
    basic_auth_header = build_basic_auth_header()
    if basic_auth_header:
        # urllib expects header name:value separately; we split at first space after name for compatibility.
        # Our header already includes 'Authorization: Basic <token>' so we parse.
        name, value = basic_auth_header.split(": ", 1)
        headers[name] = value

    response_data: dict | None = None

    current_check = 1
    while True:
        data_bytes = json.dumps(query_obj).encode("utf-8")
        req = urllib.request.Request(endpoint, data=data_bytes, headers=headers, method="POST")
        status_code = None
        body_text = ""
        try:
            with urllib.request.urlopen(req, timeout=MAX_TIME_SECONDS) as resp:
                status_code = resp.getcode()
                body_text = resp.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as e:  # HTTPError is also a valid response with body
            status_code = e.code
            try:
                body_text = e.read().decode("utf-8", errors="replace")
            except Exception:
                body_text = ""
        except Exception:
            # Any other networking issue; proceed to retry logic
            status_code = None

        if status_code == 200:
            try:
                response_data = json.loads(body_text)
                # Break early if capabilities has se:vncEnabled key
                caps_str = response_data.get("data", {}).get("session", {}).get("capabilities")
                if isinstance(caps_str, str):
                    try:
                        caps_json = json.loads(caps_str)
                        if "se:vncEnabled" in caps_json:
                            # Save the body to file for parity then break
                            _persist_body(session_id, body_text)
                            break
                    except Exception:
                        pass
                # Save after each successful 200 (even if not early break) to emulate bash behavior
                _persist_body(session_id, body_text)
            except Exception:
                # Ignore parse errors; continue polling
                pass

        current_check += 1
        if current_check == RETRY_TIME:  # Same off-by-one semantics as bash script
            break
        time.sleep(poll_interval)

    return response_data


def _persist_body(session_id: str, body_text: str) -> None:
    try:
        path = f"/tmp/graphQL_{session_id}.json"
        with open(path, "w", encoding="utf-8") as f:
            f.write(body_text)
    except Exception:
        pass  # Non-fatal


def extract_capabilities(
    session_id: str, video_cap_name: str, test_name_cap: str, video_name_cap: str
) -> Tuple[str | None, str | None, str | None]:
    """Read persisted JSON file and extract capability values.

    Returns (record_video_raw, test_name_raw, video_name_raw) which may be None or 'null'.
    """
    path = f"/tmp/graphQL_{session_id}.json"
    if not os.path.exists(path):
        return None, None, None
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        caps_str = data.get("data", {}).get("session", {}).get("capabilities")
        if not isinstance(caps_str, str):
            return None, None, None
        caps = json.loads(caps_str)
        record_video = caps.get(video_cap_name)
        test_name = caps.get(test_name_cap)
        video_name = caps.get(video_name_cap)
        return record_video, test_name, video_name
    except Exception:
        return None, None, None


def normalize_filename(raw_name: str, session_id: str, suffix_enabled: bool, trim_pattern: str) -> str:
    """Normalize the video file name.

    Steps:
      - Replace spaces with underscores.
      - Keep only allowed characters defined by trim_pattern (default [:alnum:]-_).
      - Truncate to max length 251.
      - If raw_name empty, return session_id.
      - If suffix_enabled and raw_name non-empty, append _<session_id>.
    """
    name = (raw_name or "").strip()
    if not name:
        name = session_id
        suffix_applied = False
    else:
        suffix_applied = suffix_enabled

    if suffix_applied:
        name = f"{name}_{session_id}"

    # Replace spaces
    name = name.replace(" ", "_")

    allowed_chars = derive_allowed_chars(trim_pattern)
    filtered = "".join(ch for ch in name if ch in allowed_chars)
    return filtered[:251]


def derive_allowed_chars(pattern: str) -> set[str]:
    """Translate the tr -dc style pattern (very minimally) into a set of allowed characters.

    Only special token recognized: [:alnum:]
    Other characters are taken literally except [] which are ignored.
    """
    if pattern == ":alnum:" or pattern == "[:alnum:]":  # convenience
        return set(string.ascii_letters + string.digits)
    allowed: set[str] = set()
    i = 0
    while i < len(pattern):
        if pattern.startswith("[:alnum:]", i):
            allowed.update(string.ascii_letters + string.digits)
            i += len("[:alnum:]")
            continue
        c = pattern[i]
        if c not in "[]":
            allowed.add(c)
        i += 1
    # Fallback: if somehow empty, default safe set
    return allowed or set(string.ascii_letters + string.digits + "-_")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: video_graphQLQuery.py <SESSION_ID>", file=sys.stderr)
        return 2
    session_id = argv[1]

    graphql_endpoint = get_graphql_endpoint()

    # Capability names & settings (environment overrides)
    video_cap_name = os.getenv("VIDEO_CAP_NAME", "se:recordVideo")
    test_name_cap = os.getenv("TEST_NAME_CAP", "se:name")
    video_name_cap = os.getenv("VIDEO_NAME_CAP", "se:videoName")
    trim_pattern = os.getenv("SE_VIDEO_FILE_NAME_TRIM_REGEX", "[:alnum:]-_")
    suffix_flag_raw = os.getenv("SE_VIDEO_FILE_NAME_SUFFIX", "true")
    poll_interval_raw = os.getenv("SE_VIDEO_POLL_INTERVAL", "1")

    try:
        poll_interval = float(poll_interval_raw)
    except ValueError:
        poll_interval = 1.0

    # Poll endpoint to populate /tmp file
    poll_session(graphql_endpoint, session_id, poll_interval)

    # Extract capabilities
    record_video_raw, test_name_raw, video_name_raw = extract_capabilities(
        session_id, video_cap_name, test_name_cap, video_name_cap
    )

    # Determine RECORD_VIDEO value. When the se:recordVideo capability is absent
    # (record_video_raw is None), fall back to the SE_RECORD_VIDEO env default so
    # SE_RECORD_VIDEO=false is honored, consistent with video_nodeQuery.py.
    default_record_video = os.getenv("SE_RECORD_VIDEO", "true").lower() != "false"
    if record_video_raw is None:
        record_video = default_record_video
    elif isinstance(record_video_raw, str):
        record_video = record_video_raw.lower() != "false"
    else:
        record_video = bool(record_video_raw)

    # Decide TEST_NAME referencing precedence (video_name first, then test_name)
    chosen_name: str = ""
    if video_name_raw not in (None, "null", ""):
        chosen_name = str(video_name_raw)
    elif test_name_raw not in (None, "null", ""):
        chosen_name = str(test_name_raw)
    # suffix logic: if chosen_name empty we will receive session id inside normalize_filename
    suffix_enabled = suffix_flag_raw.lower() == "true"
    normalized_name = normalize_filename(chosen_name, session_id, suffix_enabled, trim_pattern)

    # Output matches bash: RECORD_VIDEO TEST_NAME GRAPHQL_ENDPOINT
    print(f"{str(record_video).lower()} {normalized_name} {graphql_endpoint}".strip())
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main(sys.argv))
