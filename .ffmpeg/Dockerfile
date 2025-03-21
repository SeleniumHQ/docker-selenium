FROM rclone/rclone:beta AS rclone
FROM ubuntu:noble AS builder
ARG FFMPEG_VERSION="7.1"
ARG RCLONE_VER="v1.69.1"
ARG GO_VERSION="latest"

USER root

#======================================
# Install build tools
#======================================
ARG TOOLS_DEPS="autoconf automake cmake libfreetype6 gcc build-essential libtool make nasm pkg-config zlib1g-dev numactl \
libnuma-dev yasm git curl jq wget ca-certificates \
libx11-dev libxcb1-dev libpulse-dev libasound2-dev"

RUN apt-get update -qqy \
    && apt-get upgrade -yq \
    && apt-get -qqy --no-install-recommends install ${TOOLS_DEPS} \
    && apt-get -qyy clean \
    && mkdir -p /usr/local/src

COPY --from=rclone /usr/local/bin/rclone /usr/local/bin/rclone

RUN rclone --version

#======================================
# Install x264 from source
#======================================
RUN cd /usr/local/src \
    && git clone https://code.videolan.org/videolan/x264.git --filter=blob:none \
    && cd x264 \
    && ./configure --prefix="/usr/local" --enable-static \
    && make \
    && make install

#======================================
# Install FFmpeg from source
#======================================
RUN cd /usr/local/src \
    && git clone https://github.com/FFmpeg/FFmpeg.git --filter=blob:none \
    && cd FFmpeg \
    && git checkout n${FFMPEG_VERSION} \
    && rm -rf .git \
    && PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" FFMPEG_VERSION=${FFMPEG_VERSION} ./configure \
    --prefix="/usr/local" \
    --extra-cflags="-I/usr/local/include" \
    --extra-ldflags="-L/usr/local/lib" \
    --pkg-config-flags="--static" \
    --enable-gpl \
    --enable-nonfree \
    --enable-libx264 \
    --enable-libxcb \
    --enable-libpulse \
    --enable-alsa \
    --enable-static \
    && make \
    && make install

# Final stage
FROM ubuntu:noble

USER root

COPY --from=builder /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=builder /usr/local/bin/rclone /usr/local/bin/rclone

RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    libx11-6 libx11-xcb1 libxcb1 libpulse0 libasound2t64 \
    && apt-get -qqy update \
    && apt-get -yq upgrade \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN ldd /usr/local/bin/ffmpeg \
    && ffmpeg -version \
    && rclone --version

USER 101
