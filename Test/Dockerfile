FROM node:0.10-onbuild
MAINTAINER Selenium <selenium-developers@googlegroups.com>

ENV TEST_CMD node smoke-chrome.js && node smoke-firefox.js
# The remainder of this build will be completed by the upstream image's ONBUILD commands
