FROM selenium/node-chrome:2.45.0
#FROM selenium/node-*:2.45.0 Proper FROM attr will be applied throuh generate.sh

USER root

#====================================
# Scripts to run Selenium Standalone
#====================================
COPY entry_point.sh /opt/bin/entry_point.sh
RUN chmod +x /opt/bin/entry_point.sh

USER seluser

EXPOSE 4444
