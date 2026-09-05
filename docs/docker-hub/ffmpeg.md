---
description: A minimal static FFmpeg and Rclone binary for recording/uploading video function in Selenium Grid
footer: false
---
The static FFmpeg is built with enabling `libx264` and `libxcb` to record the format `x11grab` only.

Use this in build multi-stage. For example:


```Dockerfile
FROM selenium/ffmpeg:latest AS source

FROM selenium/video:latest
USER root

COPY --from=source /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=source /usr/local/bin/rclone /usr/local/bin/rclone

...
```
