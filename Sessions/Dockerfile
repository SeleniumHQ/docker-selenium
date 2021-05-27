# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.0.0-beta-4-prerelease-20210527
LABEL authors=SeleniumHQ

USER 1200

#========================
# Selenium SessionMap Configuration
#========================

EXPOSE 5556

COPY start-selenium-grid-sessions.sh \
    /opt/bin/

COPY selenium-grid-sessions.conf /etc/supervisor/conf.d/
