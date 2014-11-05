#!/bin/bash
set -e
set -x

for d in /tmp/build/**/install.sh ; do
	. $d
done

chmod +x /etc/service/**/run

apt-get clean
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/lib/apt/lists/*
