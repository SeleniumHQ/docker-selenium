# Video Recording in Dynamic Grid (Docker & Kubernetes)

Dynamic Grid starts a fresh browser environment per session — a Docker container
(`node-docker` / `standalone-docker`) or a Kubernetes Job (`node-kubernetes` /
`standalone-kubernetes`) — and can record a video of each session. Recording works
in two modes (inline or an external video container), and the recorder resolves the
output path itself.

- [Recording modes](#recording-modes)
- [Session-aware recording (no `auto` sentinel)](#session-aware-recording-no-auto-sentinel)
- [Output naming and layout](#output-naming-and-layout)
- [Docker Dynamic Grid](#docker-dynamic-grid)
- [Kubernetes Dynamic Grid](#kubernetes-dynamic-grid)
- [Uploading recordings](#uploading-recordings)
- [Recorder backends](#recorder-backends)
- [Environment variable reference](#environment-variable-reference)

## Recording modes

| Mode | What runs the recorder | Enabled by |
| --- | --- | --- |
| **External video container (sidecar)** | A separate `selenium/video` container / pod, one per session, capturing the browser's display. | Set `video-image` in the node config to a video image, e.g. `selenium/video:ffmpeg-<ver>`. |
| **Inline recording** | The browser container / pod records itself (the recorder is bundled in the browser image). No extra container. | Set `video-image = "false"` (or leave it unset). |

Recording is requested **per session** with the `se:recordVideo` capability
(`true`/`false`). A session is only recorded when recording is both enabled on the
Grid and requested by the session.

```python
options.set_capability("se:recordVideo", True)
options.set_capability("se:name", "my_test")   # used to name the video file
```

## Session-aware recording (no `auto` sentinel)

The recorder becomes **session-aware automatically when its session source is
reachable** — the Node `/status` endpoint (legacy `video.sh`) or the EventBus
(event-driven `video_service.py`). When reachable, it resolves the session id and
capabilities on its own and writes the final per-session file; the Grid no longer
injects `SE_VIDEO_FILE_NAME=auto` or forces the subfolder.

- `SE_VIDEO_FILE_NAME=auto` is still accepted as a synonym for "unset" (dynamic
  naming), so existing configs keep working — but it is no longer required.
- If **no** session source is reachable within a bounded number of attempts
  (`SE_VIDEO_WAIT_ATTEMPTS`), the recorder falls back to a **flat** standalone
  recording (the configured `SE_VIDEO_FILE_NAME`, or `video.mp4`), with no session id.

## Output naming and layout

The file **name** is resolved by one rule, identical in both recorder backends and
all deployments/modes:

1. A fixed `SE_VIDEO_FILE_NAME` (not the literal `auto`) is used verbatim.
2. Otherwise the name is derived from `se:videoName` → `se:name` → `<sessionId>`,
   with a `_<sessionId>` suffix when `SE_VIDEO_FILE_NAME_SUFFIX=true` (default) and the
   name came from capabilities.

The **subfolder** is an independent toggle, `SE_VIDEO_SESSION_SUBFOLDER`:

```
SE_VIDEO_SESSION_SUBFOLDER=true   ->  <assets>/<sessionId>/<name>.mp4
SE_VIDEO_SESSION_SUBFOLDER=false  ->  <assets>/<name>.mp4   (flat)
```

The session id only ever names the **folder** — it does not change the file name. A
fixed name combined with the subfolder is therefore collision-free across sessions
(`<assets>/<sessionId>/<fixed_name>.mp4`).

> **Concurrency caveat.** With the subfolder **disabled**, a *fixed* `SE_VIDEO_FILE_NAME`
> has no session id anywhere and concurrent sessions would overwrite each other. Enable
> `SE_VIDEO_SESSION_SUBFOLDER=true` for concurrent recording, or rely on the caps-derived
> name (which carries the `_<sessionId>` suffix). The shipped Dynamic Grid manifests set
> `SE_VIDEO_SESSION_SUBFOLDER=true` by default.

Example layout (subfolder enabled):

```
/opt/selenium/assets/1cf10676…/test_with_frames_ChromeTests.mp4
/opt/selenium/assets/707b256f…/test_visit_basic_auth_secured_page_ChromeTests.mp4
/opt/selenium/assets/7ede90ed…/test_title_ChromeTests.mp4
…
```

## Docker Dynamic Grid

The `node-docker` / `standalone-docker` image starts each browser as a Docker
container via the Docker API. Recording is configured in the Docker node config
(`docker.toml`). The Grid binds the **assets root** to `/videos` for both inline and
the external video container, so the `SE_VIDEO_SESSION_SUBFOLDER` toggle governs the
layout the same way in both modes (no per-session bind, no double-nesting special case).

### Inline (`video-image = "false"`)

```toml
[docker]
configs = [
    "selenium/standalone-chromium:<tag>", '{"browserName": "chrome", "platformName": "linux"}',
    # …
]
video-image = "false"
```

The browser container records itself. Set `SE_VIDEO_SESSION_SUBFOLDER=true` on the node
(recommended) to get `<assets>/<sessionId>/<name>.mp4`.

### External video container (sidecar)

```toml
[docker]
configs = [ /* … */ ]
video-image = "selenium/video:ffmpeg-<ver>"
```

A `selenium/video` container is started **after** the session is created, so the Grid
knows the session id and binds that session's assets path directly
(`<assets>/<sessionId>` → `/videos`); it blanks `SE_VIDEO_SESSION_SUBFOLDER` so the
recorder does not nest a second folder. The recording therefore lands at
`<assets>/<sessionId>/<name>.mp4` via the **mount** — no session discovery required, and
it works with any video image (including a pinned older tag).

> This per-session-mount is unique to the **Docker external** video container (the
> session exists before the container starts). All other cases (Docker inline,
> Kubernetes inline/external) mount the assets root and rely on the
> `SE_VIDEO_SESSION_SUBFOLDER` toggle + the recorder discovering the session.

## Kubernetes Dynamic Grid

The `node-kubernetes` / `standalone-kubernetes` image starts each browser as a
Kubernetes Job. The assets volume is mounted at `/videos`; the recorder writes the
final `<sessionId>/<name>.mp4` itself (there is no post-session relocation).

### Inline (no video sidecar)

```yaml
# node-kubernetes / standalone-kubernetes Deployment
env:
  - name: SE_RECORD_VIDEO
    value: "true"
  - name: SE_VIDEO_SESSION_SUBFOLDER   # store each recording under <assets>/<sessionId>/
    value: "true"
```

`SE_RECORD_VIDEO=true` is propagated to each browser Job, which records itself
session-aware and writes to its final per-session location.

### External video container (sidecar)

```toml
[kubernetes]
configs = [ /* … */ ]
video-image = "selenium/video:ffmpeg-<ver>"
```

A video sidecar is added to each browser Job. It records session-aware and honors the
same `SE_VIDEO_SESSION_SUBFOLDER` toggle (passed through from the node).

## Uploading recordings

Recordings can be uploaded (via Rclone) to a remote destination, in addition to (or
instead of) being kept locally.

| Variable | Effect |
| --- | --- |
| `SE_UPLOAD_DESTINATION_PREFIX` | Remote name + path to upload to (e.g. `myftp://ftp/seluser`). A non-empty value enables upload. |
| `SE_UPLOAD_RETAIN_LOCAL_FILE` | `true` → Rclone **copy** (keep the local per-session file **and** upload). `false` (default) → Rclone **move** (upload, then delete the local file). |

Uploaded files are placed at `<destination>/<file>.mp4` (the session-id subfolder is
**not** recreated at the destination). If you rely on the on-disk per-session layout
(for example a test that inspects it), set `SE_UPLOAD_RETAIN_LOCAL_FILE=true` so the
local copy survives the upload.

## Recorder backends

Two recorder implementations produce the video, selected by `SE_VIDEO_EVENT_DRIVEN`:

| Backend | Selected by | Session source |
| --- | --- | --- |
| `video_service.py` (event-driven) | `SE_VIDEO_EVENT_DRIVEN=true` (default) | Grid EventBus + Node `/status` |
| `video.sh` (polling) | `SE_VIDEO_EVENT_DRIVEN=false` | Node `/status` endpoint |

Both apply the same naming rule and the `SE_VIDEO_SESSION_SUBFOLDER` toggle, and both
fall back to a flat standalone recording when no session source is reachable.

## Environment variable reference

| Variable | Default | Applies to | Purpose |
| --- | --- | --- | --- |
| `se:recordVideo` (capability) | — | session | Request/skip recording for this session. |
| `SE_RECORD_VIDEO` | `false` | node (inline) | Enable inline recording on the node. |
| `SE_VIDEO_RECORD_STANDALONE` | — | recorder | Record the whole display (used by inline recording). |
| `SE_VIDEO_FILE_NAME` | *(unset)* | recorder | Fixed output name; `auto`/unset ⇒ derive from capabilities. |
| `SE_VIDEO_FILE_NAME_SUFFIX` | `true` | recorder | Append a session-id suffix to caps-derived names. |
| `SE_VIDEO_SESSION_SUBFOLDER` | `false` | recorder | Write into `<assets>/<sessionId>/`. Honored directly by the recorder. Blanked by the Grid for the Docker external video container (its mount is already per-session). |
| `SE_VIDEO_WAIT_ATTEMPTS` | `50` | recorder | Bounded attempts to reach the session source before the flat fallback. |
| `SE_VIDEO_UPLOAD_ENABLED` / `SE_UPLOAD_DESTINATION_PREFIX` | — | recorder | Enable and target video upload. |
| `SE_UPLOAD_RETAIN_LOCAL_FILE` | `false` | recorder | Keep the local file after upload (copy vs move). |
| `se:videoName` / `se:name` (capabilities) | — | session | Provide the video/test name used for caps-derived naming. |
