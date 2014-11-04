#!/usr/bin/env bash
export CONTAINER_IP=$(ip addr show dev eth0 | grep "inet " | awk '{print $2}' | cut -d '/' -f 1)
export DOCKER_HOST_IP=$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')

# As of docker >= 1.2.0 is possible to append our stuff directly into /etc/hosts
cat /tmp/hosts >> /etc/hosts
echo "docker.host.dev   $DOCKER_HOST_IP" >> /etc/hosts
echo "docker.guest.dev  $CONTAINER_IP"   >> /etc/hosts
