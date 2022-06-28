# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.3.0-20220628
LABEL authors=SeleniumHQ

USER root

#==============
# Socat to proxy docker.sock when mounted
#==============
RUN apt-get update -qqy \
  && apt-get -qqy install socat \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

USER 1200

#========================
# Selenium Standalone Docker Configuration
#========================

EXPOSE 4444

COPY start-selenium-grid-docker.sh \
    config.toml \
    start-socat.sh \
    /opt/bin/

COPY selenium-grid-docker.conf /etc/supervisor/conf.d/

