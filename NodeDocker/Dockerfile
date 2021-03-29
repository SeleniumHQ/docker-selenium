# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.0.0-beta-3-prerelease-20210329
LABEL authors=SeleniumHQ

USER 1200

#========================
# Selenium Standalone Docker Configuration
#========================

EXPOSE 4444

COPY start-selenium-grid-node-docker.sh \
    config.toml \
    /opt/bin/

COPY selenium-grid-node-docker.conf /etc/supervisor/conf.d/

