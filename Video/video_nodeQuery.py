#!/usr/bin/env python3

import json
import os
import re
import sys

default_trim_pattern = "[^a-zA-Z0-9-_]"


def main() -> None:
    """
    Process video recording configuration based on session capabilities.

    Args:
        sys.argv[1]: SESSION_ID
        sys.argv[2]: SESSION_CAPABILITIES (JSON string)

    Outputs:
        Space-separated values: RECORD_VIDEO TEST_NAME
    """
    # Define parameters
    session_id = sys.argv[1] if len(sys.argv) > 1 else ""
    session_capabilities = sys.argv[2] if len(sys.argv) > 2 else ""

    # Environment variables with defaults
    video_cap_name = os.environ.get("VIDEO_CAP_NAME", "se:recordVideo")
    default_record_video = os.environ.get("SE_RECORD_VIDEO", "true").lower() != "false"
    test_name_cap = os.environ.get("TEST_NAME_CAP", "se:name")
    video_name_cap = os.environ.get("VIDEO_NAME_CAP", "se:videoName")
    video_file_name_trim = os.environ.get("SE_VIDEO_FILE_NAME_TRIM_REGEX", default_trim_pattern)
    video_file_name_suffix = os.environ.get("SE_VIDEO_FILE_NAME_SUFFIX", "true")
    # A fixed output name; the literal "auto" (and empty) means "unset" -> derive from caps.
    configured_file_name = os.environ.get("FILE_NAME", os.environ.get("SE_VIDEO_FILE_NAME", "")).strip()

    # Initialize variables
    record_video = None
    test_name = None
    video_name = None

    # Extract values from session capabilities if provided
    if session_capabilities:
        try:
            capabilities = json.loads(session_capabilities)
            record_video = capabilities.get(video_cap_name)
            test_name = capabilities.get(test_name_cap)
            video_name = capabilities.get(video_name_cap)
        except (json.JSONDecodeError, AttributeError):
            # If JSON parsing fails, continue with None values
            pass

    # Check if enabling to record video; fall back to SE_RECORD_VIDEO when capability is absent
    if record_video is None:
        record_video = "true" if default_record_video else "false"
    elif (isinstance(record_video, str) and record_video.lower() == "false") or record_video is False:
        record_video = "false"
    else:
        record_video = "true"

    # Resolve the output file name (without extension). A fixed SE_VIDEO_FILE_NAME wins over
    # caps-derived naming; "auto"/empty is treated as unset and falls back to dynamic naming.
    if configured_file_name and configured_file_name.lower() != "auto":
        # Strip a trailing .mp4 so the consumer appends the extension uniformly.
        if configured_file_name.lower().endswith(".mp4"):
            configured_file_name = configured_file_name[:-4]
        test_name = normalize_filename(configured_file_name, video_file_name_trim)
    else:
        # Check if video file name is set via capabilities
        if video_name and video_name != "null":
            test_name = video_name
        elif test_name and test_name != "null":
            test_name = test_name
        else:
            test_name = ""

        # Check if append session ID to the video file name suffix
        if not test_name:
            test_name = session_id
        elif video_file_name_suffix.lower() == "true":
            test_name = f"{test_name}_{session_id}"

        # Normalize the video file name
        test_name = normalize_filename(test_name, video_file_name_trim)

    # Output the values for other scripts consuming
    print(f"{record_video} {test_name}")


def normalize_filename(filename: str, trim_pattern: str) -> str:
    """
    Normalize the filename by replacing spaces with underscores,
    keeping only allowed characters, and truncating to 251 characters.

    Args:
        filename: The original filename
        trim_pattern: Pattern defining allowed characters

    Returns:
        Normalized filename
    """
    if not filename:
        return ""

    # Replace spaces with underscores
    normalized = filename.replace(" ", "_")

    try:
        pattern = re.compile(trim_pattern)
    except re.error:
        pattern = re.compile(default_trim_pattern)

    # Remove disallowed characters
    normalized = re.sub(pattern, "", normalized)

    # Truncate to 251 characters
    return normalized[:251]


if __name__ == "__main__":
    main()
