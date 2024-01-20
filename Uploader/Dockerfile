ARG BASED_TAG
FROM rclone/rclone:${BASED_TAG}

RUN apk update \
  && apk add --no-cache --update \
    bash \
    curl \
    wget \
    jq \
  && rm -rf /tmp/* /var/cache/apk/*

USER rclone
