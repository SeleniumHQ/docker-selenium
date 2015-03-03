FROM selenium/base:2.44.0
MAINTAINER Selenium <selenium-developers@googlegroups.com>

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "US/Pacific"
RUN echo "US/Pacific" | sudo tee /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#==============
# PhantomJS
#==============
RUN apt-get update -y
RUN apt-get install bzip2 libfreetype6 libfontconfig1  -y
RUN wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2
RUN tar -xvjf phantomjs-1.9.8-linux-x86_64.tar.bz2 && rm phantomjs-1.9.8-linux-x86_64.tar.bz2
RUN mv /phantomjs-1.9.8-linux-x86_64 /usr/local/phantomjs-1.9.8-linux-x86_64
RUN ln -s /usr/local/phantomjs-1.9.8-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs

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

USER seluser

CMD ["/opt/bin/entry_point.sh"]
