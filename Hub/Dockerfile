# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/base:4.0.0-20211102
LABEL authors=SeleniumHQ

USER 1200

#========================
# Selenium Hub Configuration
#========================

EXPOSE 4442
EXPOSE 4443
EXPOSE 4444

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT 300
# In seconds, maps to "--session-retry-interval"
ENV SE_SESSION_RETRY_INTERVAL 5
# Boolean value, maps "--relax-checks"
ENV SE_RELAX_CHECKS true

COPY start-selenium-grid-hub.sh \
    /opt/bin/

COPY selenium-grid-hub.conf /etc/supervisor/conf.d/
