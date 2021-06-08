# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.0.0-beta-4-20210608
LABEL authors=SeleniumHQ

USER 1200

#========================
# Selenium SessionQueue Configuration
#========================

EXPOSE 5559

COPY start-selenium-grid-session-queue.sh \
    /opt/bin/

COPY selenium-grid-session-queue.conf /etc/supervisor/conf.d/
