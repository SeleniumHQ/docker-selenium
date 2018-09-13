#!/bin/bash

# https://github.com/SeleniumHQ/docker-selenium/issues/785
# Returns a random number between 1 and 99 to be used in xvfb-run
function get_random_server_number() {
  echo $((1 + RANDOM % 99))
}