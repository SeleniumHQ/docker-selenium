# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
<<<<<<< HEAD
FROM local-seleniarm/node-firefox:4.0.0-20211111
LABEL authors=SeleniumHQ,sj26,jamesmortensen
=======
FROM selenium/node-firefox:4.1.0-prerelease-20211105
LABEL authors=SeleniumHQ
>>>>>>> 2d1e3db0c6ac55e0e5c9d924a8f2b528d4713319

USER 1200

#====================================
# Scripts to run Selenium Standalone
#====================================
COPY start-selenium-standalone.sh /opt/bin/start-selenium-standalone.sh

#==============================
# Supervisor configuration file
#==============================
COPY selenium.conf /etc/supervisor/conf.d/

# Copying configuration script generator
COPY generate_config /opt/bin/generate_config

# Boolean value, maps "--relax-checks"
ENV SE_RELAX_CHECKS true

EXPOSE 4444


