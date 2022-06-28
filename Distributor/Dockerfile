# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.3.0-20220628
LABEL authors=SeleniumHQ

USER 1200

#========================
# Selenium Distributor Configuration
#========================

EXPOSE 5553

COPY start-selenium-grid-distributor.sh \
    /opt/bin/

COPY selenium-grid-distributor.conf /etc/supervisor/conf.d/
