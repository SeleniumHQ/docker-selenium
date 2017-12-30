#!/usr/bin/env bash

# Due to the dependency GNU sed, we're skipping this part when running
# on Mac OS X.
if [ "$(uname)" != 'Darwin' ] ; then
  echo 'Testing shell functions...'
  which bats > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "Could not find 'bats'. Please install it first, e.g., following https://github.com/sstephenson/bats#installing-bats-from-source."
    exit 1
  fi
  NodeBase/test-functions.sh || exit 1
else
  echo 'Skipping shell functions test on Mac OS X.'
fi

echo "Done testing shell functions!"