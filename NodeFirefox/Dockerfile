# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
<<<<<<< HEAD
FROM local-seleniarm/node-base:4.0.0-20211111
LABEL authors=SeleniumHQ,sj26,jamesmortensen

#FROM local-seleniarm/node-base:4.0.0-20211018
#LABEL authors=SeleniumHQ,sj26,jamesmortensen
=======
FROM selenium/node-base:4.1.0-prerelease-20211105
LABEL authors=SeleniumHQ
>>>>>>> 2d1e3db0c6ac55e0e5c9d924a8f2b528d4713319

USER root

#=========
# Firefox
#=========
RUN echo "deb http://ftp.hk.debian.org/debian/ sid main" >> /etc/apt/sources.list \
  && apt-get update -qqy \
  && apt-get -qqy install firefox-esr libavcodec-extra \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# geckodriver was built using the local-seleniarm/geckodriver-arm64 Debian image
COPY geckodriver /usr/local/bin/

USER 1200

#============================================
# Dumping Browser name and version for config
#============================================
RUN echo "firefox" > /opt/selenium/browser_name