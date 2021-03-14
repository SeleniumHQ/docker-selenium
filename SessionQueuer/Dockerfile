# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.0.0-beta-2-prerelease-20210314
LABEL authors=SeleniumHQ

USER 1200

#========================
# Selenium SessionQueuer Configuration
#========================

EXPOSE 5559

COPY start-selenium-grid-session-queuer.sh \
    /opt/bin/

COPY selenium-grid-session-queuer.conf /etc/supervisor/conf.d/
