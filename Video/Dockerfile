ARG NAMESPACE=selenium
ARG BASE=base
ARG VERSION=latest
ARG FFMPEG_BASED_NAME=selenium
ARG FFMPEG_BASED_TAG=latest
FROM ${FFMPEG_BASED_NAME}/ffmpeg:${FFMPEG_BASED_TAG} AS source

# Final stage
FROM ${NAMESPACE}/${BASE}:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

COPY --from=source /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=source /usr/local/bin/rclone /usr/local/bin/rclone

RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    libx11-6 libx11-xcb1 libxcb1 libpulse0 libasound2t64 \
    x11-xserver-utils x11-utils \
    python3-pip \
    && apt-get -qqy update \
    && apt-get -yq upgrade \
    && pip install --upgrade --break-system-packages --no-cache-dir setuptools psutil \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY *.conf /etc/supervisor/conf.d/
COPY --chown="${SEL_UID}:${SEL_GID}" *.sh *.py /opt/bin/

USER ${SEL_UID}

RUN ffmpeg -version \
    && rclone --version \
    && touch /opt/selenium/upload.conf

ENV DISPLAY_NUM="99" \
    DISPLAY_CONTAINER_NAME="selenium" \
    SE_RECORD_VIDEO="true" \
    SE_RECORD_AUDIO="false" \
    SE_AUDIO_SOURCE="-f pulse -ac 2 -i default" \
    SE_SERVER_PROTOCOL="http" \
    SE_VIDEO_POLL_INTERVAL="1" \
    SE_FRAME_RATE="15" \
    SE_CODEC="libx264" \
    SE_PRESET="-preset ultrafast" \
    VIDEO_FOLDER="/videos" \
    SE_VIDEO_FILE_NAME="video.mp4" \
    SE_VIDEO_FILE_NAME_TRIM_REGEX="[:alnum:]-_" \
    # Environment variables for the uploader
    RCLONE_CONFIG="/opt/selenium/upload.conf" \
    SE_VIDEO_UPLOAD_ENABLED="false" \
    SE_VIDEO_INTERNAL_UPLOAD="true" \
    SE_UPLOAD_DESTINATION_PREFIX=""

EXPOSE 9000
