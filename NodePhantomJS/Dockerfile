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
RUN apt-get install bzip2 libfreetype6 libfontconfig1 unzip -y
wget https://github.com/eugene1g/phantomjs/releases/download/2.0.0-bin/phantomjs-2.0.0-ubuntu_x86_64.zip
unzip phantomjs-2.0.0-ubuntu_x86_64.zip -d .
RUN mv phantomjs /usr/local/
RUN chmod +x /usr/local/phantomjs
RUN ln -s /usr/local/phantomjs /usr/local/bin/phantomjs

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
