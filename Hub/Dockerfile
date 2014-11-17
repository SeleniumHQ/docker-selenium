FROM elgalu/selenium-base:2.44.0
MAINTAINER Selenium <selenium-developers@googlegroups.com>

#==========================================
# Scripts to run selenium hub as a service
#==========================================
COPY ./etc /etc
# Allow child images to also chime in on which services to run
RUN chmod +x /etc/my_init.d/*.sh \
  && chmod +x /etc/service/**/run
