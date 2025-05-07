FROM ubuntu:noble AS builder
ARG FFMPEG_VERSION="7.1.1"
ARG RCLONE_VER="v1.69.2"
ARG GO_VERSION="latest"
ARG GO_CRYPTO_VERSION="v0.35.0"
ARG GO_OAUTH2_VERSION="v0.27.0"
ARG GO_NET_VERSION="v0.38.0"
ARG GOLANG_JWT_V4_VERSION="v4.5.2"
ARG GOLANG_JWT_V5_VERSION="v5.2.2"

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

RUN if [ "${GO_VERSION}" = "latest" ]; then \
        GO_VERSION=$(curl -sk https://go.dev/dl/?mode=json | jq -r '.[0].version'); \
    fi \
    && curl -skLO https://go.dev/dl/${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz \
    && tar -xf ${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz -C /usr/local \
    && rm -rf ${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz* \
    && ln -sf /usr/local/go/bin/go /usr/bin/go \
    && go version

RUN cd /usr/local/src \
    && git clone https://github.com/rclone/rclone.git --filter=blob:none \
    && cd rclone \
    && git checkout ${RCLONE_VER} \
    # Patch deps version in go.mod to fix CVEs
    && sed -i "s|golang.org/x/crypto v.*|golang.org/x/crypto ${GO_CRYPTO_VERSION}|g" go.mod \
    && sed -i "s|golang.org/x/oauth2 v.*|golang.org/x/oauth2 ${GO_OAUTH2_VERSION}|g" go.mod \
    && sed -i "s|golang.org/x/net v.*|golang.org/x/net ${GO_NET_VERSION}|g" go.mod \
    && sed -i "s|github.com/golang-jwt/jwt/v5 v.*|github.com/golang-jwt/jwt/v5 v5.2.2|g" go.mod \
    && sed -i "s|github.com/golang-jwt/jwt/v4 v.*|github.com/golang-jwt/jwt/v4 v4.5.2|g" go.mod \
    && go mod tidy \
    # Build rclone
    && make \
    && mv ~/go/bin/rclone /usr/local/bin/ \
    && rclone version

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
