FROM jrottenberg/ffmpeg:4.3.1-ubuntu2004
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu focal main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu focal-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu focal-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================
# Supervisor
#========================
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    supervisor x11-xserver-utils x11-utils curl jq python3-pip \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#======================================
# Add Supervisor configuration files
#======================================
COPY supervisord.conf /etc
COPY entry_point.sh video.sh video_ready.py /opt/bin/
RUN cd /opt/bin && pip install psutil

RUN  mkdir -p /var/run/supervisor /var/log/supervisor /videos

ENTRYPOINT ["/opt/bin/entry_point.sh"]
CMD ["/opt/bin/entry_point.sh"]

ENV DISPLAY_NUM 99
ENV DISPLAY_CONTAINER_NAME selenium
ENV SE_SCREEN_WIDTH 1360
ENV SE_SCREEN_HEIGHT 1020
ENV SE_FRAME_RATE 15
ENV SE_CODEC libx264
ENV SE_PRESET "-preset ultrafast"
ENV FILE_NAME video.mp4
ENV SE_VIDEO_FOLDER /videos

EXPOSE 9000
