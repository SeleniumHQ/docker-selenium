# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM urosporo/testbench-node-firefox:5.1.2
LABEL authors=SeleniumHQ and Urosporo

USER seluser

#====================================
# Scripts to run Vaadin Testbench Standalone
#====================================
COPY start-testbench-standalone.sh /opt/bin/start-testbench-standalone.sh

#==============================
# Supervisor configuration file
#==============================
COPY testbench.conf /etc/supervisor/conf.d/


EXPOSE 4444
