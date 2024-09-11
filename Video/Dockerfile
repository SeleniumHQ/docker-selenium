ARG NAMESPACE=linuxserver
ARG BASED_TAG=latest
FROM $NAMESPACE/ffmpeg:$BASED_TAG
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

ARG RCLONE_VERSION=current
#Arguments to define the user running the container
ARG SEL_USER=seluser
ARG SEL_GROUP=${SEL_USER}
ARG HOME=/home/${SEL_USER}
ARG UID=1200
ARG GID=1201
ARG VIDEO_FOLDER=/videos

USER root
#================================================
# Customize sources for apt-get
#================================================
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
      echo "deb http://archive.ubuntu.com/ubuntu noble main universe\n" > /etc/apt/sources.list \
      && echo "deb http://archive.ubuntu.com/ubuntu noble-updates main universe\n" >> /etc/apt/sources.list \
      && echo "deb http://security.ubuntu.com/ubuntu noble-security main universe\n" >> /etc/apt/sources.list ; \
    fi

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    PIP_ROOT_USER_ACTION=ignore

#========================
# Supervisor
#========================
RUN apt-get -qqy update \
  && apt-get upgrade -yq \
  && apt-get -qqy --no-install-recommends install \
    supervisor x11-xserver-utils x11-utils libxcb1-dev curl jq python3-pip tzdata acl unzip python3-psutil \
  && pip install --no-cache-dir --upgrade --break-system-packages setuptools \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ="UTC"
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    cat /etc/timezone

#======================================
# Configure environement
#======================================
ENV SEL_USER=${SEL_USER} \
    SEL_UID=${UID} \
    SEL_GID=${GID} \
    HOME=${HOME}

#========================================
# Add normal user and group with passwordless sudo
#========================================
RUN --mount=type=secret,id=SEL_PASSWD \
  groupadd ${SEL_GROUP} \
         --gid ${SEL_GID} \
  && useradd ${SEL_USER} \
         --create-home \
         --gid ${SEL_GID} \
         --shell /bin/bash \
         --uid ${SEL_UID} \
  && usermod -a -G sudo ${SEL_USER} \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo "${SEL_USER}:$(cat /run/secrets/SEL_PASSWD)" | chpasswd

#======================================
# Add Supervisor configuration files
#======================================
COPY supervisord.conf /etc
COPY --chown="${SEL_UID}:${SEL_GID}" entry_point.sh video.sh video_ready.py video_graphQLQuery.sh video_gridUrl.sh /opt/bin/

#======================================
# Add RCLONE for uploading videos
#======================================
RUN curl -fLo /tmp/rclone.zip https://downloads.rclone.org/rclone-${RCLONE_VERSION}-linux-$(dpkg --print-architecture).zip \
  && unzip -a /tmp/rclone.zip -d /tmp \
  && mv /tmp/rclone-*-linux-*/rclone /usr/local/bin/ \
  && rm -rf /tmp/rclone-*
COPY --chown="${SEL_UID}:${SEL_GID}" upload.sh upload.conf /opt/bin/
ENV SE_VIDEO_UPLOAD_ENABLED=false \
    SE_VIDEO_INTERNAL_UPLOAD=true \
    SE_UPLOAD_DESTINATION_PREFIX=""

RUN  mkdir -p /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} \
  && chown -R ${SEL_USER}:${SEL_GROUP} /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} ${HOME} \
  && chmod -R 775 /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} ${HOME} \
  && chgrp -R 0 /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} ${HOME} \
  && chmod -R g=u /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} ${HOME} \
  && setfacl -Rdm u:${SEL_USER}:rwx,g:${SEL_GROUP}:rwx /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} ${HOME}

USER ${SEL_UID}

ENTRYPOINT ["/opt/bin/entry_point.sh"]
CMD ["/opt/bin/entry_point.sh"]

ENV DISPLAY_NUM=99 \
    DISPLAY_CONTAINER_NAME=selenium \
    SE_SERVER_PROTOCOL="http" \
    SE_VIDEO_POLL_INTERVAL=1 \
    SE_SCREEN_WIDTH=1920 \
    SE_SCREEN_HEIGHT=1080 \
    SE_FRAME_RATE=15 \
    SE_CODEC=libx264 \
    SE_PRESET="-preset ultrafast" \
    VIDEO_FOLDER=${VIDEO_FOLDER} \
    SE_VIDEO_FILE_NAME=video.mp4 \
    SE_VIDEO_FILE_NAME_TRIM_REGEX="[:alnum:]-_" \
    SE_SUPERVISORD_LOG_LEVEL="info" \
    SE_SUPERVISORD_CHILD_LOG_DIR="/tmp" \
    SE_SUPERVISORD_LOG_FILE="/tmp/supervisord.log" \
    SE_SUPERVISORD_PID_FILE="/tmp/supervisord.pid"

EXPOSE 9000
