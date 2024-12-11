FROM ubuntu:noble AS builder
ARG VERSION_FFMPEG="7.1"
ARG VERSION_RCLONE="v1.68.2"
ARG VERSION_GO="latest"

USER root

#======================================
# Install build tools
#======================================
ARG TOOLS_DEPS="autoconf automake cmake libfreetype6 gcc build-essential libtool make nasm pkg-config zlib1g-dev numactl \
libnuma-dev libx11-6 libxcb1 libxcb1-dev yasm git curl jq wget ca-certificates"

RUN apt-get update -qqy \
    && apt-get upgrade -yq \
    && apt-get -qqy --no-install-recommends install ${TOOLS_DEPS} \
    && apt-get -qyy clean \
    && mkdir -p /usr/local/src

RUN if [ "${VERSION_GO}" = "latest" ]; then \
        VERSION_GO=$(curl -sk https://go.dev/dl/?mode=json | jq -r '.[0].version'); \
    fi \
    && curl -skLO https://go.dev/dl/$VERSION_GO.linux-$(dpkg --print-architecture).tar.gz \
    && tar -xf $VERSION_GO.linux-$(dpkg --print-architecture).tar.gz -C /usr/local \
    && rm -rf $VERSION_GO.linux-$(dpkg --print-architecture).tar.gz* \
    && ln -sf /usr/local/go/bin/go /usr/bin/go \
    && go version

RUN cd /usr/local/src \
    && git clone https://github.com/rclone/rclone.git \
    && cd rclone \
    && git checkout $VERSION_RCLONE \
    && make \
    && mv ~/go/bin/rclone /usr/local/bin/ \
    && rclone version

#======================================
# Install x264 from source
#======================================
RUN cd /usr/local/src \
    && git clone https://code.videolan.org/videolan/x264.git \
    && cd x264 \
    && ./configure --prefix="/usr/local" --enable-static \
    && make \
    && make install

#======================================
# Install FFmpeg from source
#======================================
RUN cd /usr/local/src \
    && git clone https://github.com/FFmpeg/FFmpeg.git \
    && cd FFmpeg \
    && git checkout release/$VERSION_FFMPEG \
    && PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" ./configure \
    --prefix="/usr/local" \
    --extra-cflags="-I/usr/local/include" \
    --extra-ldflags="-L/usr/local/lib" \
    --pkg-config-flags="--static" \
    --enable-gpl \
    --enable-nonfree \
    --enable-libx264 \
    --enable-libxcb \
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
    libx11-dev libxcb1 libxcb-shm0 \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN ffmpeg -version \
    && rclone --version
