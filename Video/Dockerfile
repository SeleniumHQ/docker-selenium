FROM jrottenberg/ffmpeg:6.0-alpine
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

#========================
# Supervisor
#========================
RUN apk update \
  && apk upgrade \
  && apk add --no-cache --update --virtual .build-deps supervisor bash curl jq xset xdpyinfo python3 py3-psutil py3-pip \
  && ln -sf python3 /usr/bin/python \
  && rm -rf /tmp/* /var/cache/apk/*

ENV PYTHONUNBUFFERED=1
RUN python3 -m pip install --no-cache --upgrade --no-cache-dir pip urllib3 setuptools requests wheel

#======================================
# Add Supervisor configuration files
#======================================
ENV SE_VIDEO_FOLDER /videos
RUN mkdir -p /opt/bin/
RUN mkdir -p /var/run/supervisor /var/log/supervisor ${SE_VIDEO_FOLDER}

COPY supervisord.conf /etc
COPY entry_point.sh video.sh video_ready.py /opt/bin/

RUN chmod +x /opt/bin/*
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

EXPOSE 9000
