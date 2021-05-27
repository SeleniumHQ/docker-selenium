# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.0.0-beta-4-prerelease-20210527
LABEL authors=SeleniumHQ

USER 1200

#========================
# Selenium Distributor Configuration
#========================

EXPOSE 5553

COPY start-selenium-grid-distributor.sh \
    /opt/bin/

COPY selenium-grid-distributor.conf /etc/supervisor/conf.d/
