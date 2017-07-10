# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/node-base:3.4.0-einsteinium
LABEL authors=SeleniumHQ
MAINTAINER Ken.l.ma
# used as a fork from the selenium docker images
# update phantomjs to 2.0.0

USER root

#==============
# PhantomJS
#==============
RUN apt-get update -y
RUN apt-get install bzip2 libfreetype6 libfontconfig1 -y
COPY phantomjs /usr/local/bin/phantomjs
RUN chmod +x /usr/local/bin/phantomjs
RUN wget http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu52_52.1-3ubuntu0.6_amd64.deb
RUN chmod +x libicu52_52.1-3ubuntu0.6_amd64.deb
RUN dpkg -i libicu52_52.1-3ubuntu0.6_amd64.deb

#==============================
# Scripts to run Selenium Node
#==============================
COPY entry_point.sh /opt/bin/entry_point.sh
RUN chmod +x /opt/bin/entry_point.sh

#============================
# Some configuration options
#============================
ENV SCREEN_WIDTH 1360
ENV SCREEN_HEIGHT 1020
ENV SCREEN_DEPTH 24
ENV DISPLAY :99.0
ENV NODE_APPLICATION_NAME ""

USER seluser

CMD ["/opt/bin/entry_point.sh"]
