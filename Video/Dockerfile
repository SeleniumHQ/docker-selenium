ARG NAMESPACE
ARG BASED_TAG
FROM $NAMESPACE/ffmpeg:$BASED_TAG
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

ARG RCLONE_VERSION=current
#Arguments to define the user running the container
ARG SEL_USER=seluser
ARG SEL_GROUP=${SEL_USER}
ARG SEL_PASSWD=secret
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
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    cat /etc/timezone

#======================================
# Configure environement
#======================================
ENV SEL_USER=${SEL_USER}
ENV SEL_UID=${UID}
ENV SEL_GID=${GID}
ENV HOME=/home/${SEL_USER}

#========================================
# Add normal user and group with passwordless sudo
#========================================
RUN groupadd ${SEL_GROUP} \
         --gid ${SEL_GID} \
  && useradd ${SEL_USER} \
         --create-home \
         --gid ${SEL_GID} \
         --shell /bin/bash \
         --uid ${SEL_UID} \
  && usermod -a -G sudo ${SEL_USER} \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo "${SEL_USER}:${SEL_PASSWD}" | chpasswd

#======================================
# Add Supervisor configuration files
#======================================
COPY supervisord.conf /etc
COPY --chown="${SEL_UID}:${SEL_GID}" entry_point.sh video.sh video_ready.py video_graphQLQuery.sh /opt/bin/

#======================================
# Add RCLONE for uploading videos
#======================================
RUN curl -fLo /tmp/rclone.zip https://downloads.rclone.org/rclone-${RCLONE_VERSION}-linux-$(dpkg --print-architecture).zip \
  && unzip -a /tmp/rclone.zip -d /tmp \
  && mv /tmp/rclone-*-linux-*/rclone /usr/local/bin/ \
  && rm -rf /tmp/rclone-*
COPY --chown="${SEL_UID}:${SEL_GID}" upload.sh upload.conf /opt/bin/
ENV SE_VIDEO_UPLOAD_ENABLED false
ENV SE_UPLOAD_DESTINATION_PREFIX ""
ENV SE_VIDEO_INTERNAL_UPLOAD false
ENV UPLOAD_OPTS "-P"

RUN  mkdir -p /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} \
  && chown -R ${SEL_USER}:${SEL_GROUP} /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} $HOME \
  && chmod -R 775 /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} $HOME \
  && chgrp -R 0 /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} $HOME \
  && chmod -R g=u /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} $HOME \
  && setfacl -Rdm u:${SEL_USER}:rwx,g:${SEL_GROUP}:rwx /var/run/supervisor /var/log/supervisor ${VIDEO_FOLDER} $HOME

USER ${SEL_UID}

ENTRYPOINT ["/opt/bin/entry_point.sh"]
CMD ["/opt/bin/entry_point.sh"]

ENV DISPLAY_NUM 99
ENV DISPLAY_CONTAINER_NAME selenium
ENV SE_SCREEN_WIDTH 1360
ENV SE_SCREEN_HEIGHT 1020
ENV SE_FRAME_RATE 15
ENV SE_CODEC libx264
ENV SE_PRESET "-preset ultrafast"
ENV VIDEO_FOLDER ${VIDEO_FOLDER}
ENV SE_VIDEO_FILE_NAME video.mp4
ENV SE_VIDEO_FILE_NAME_TRIM_REGEX "[:alnum:]-_"

EXPOSE 9000
