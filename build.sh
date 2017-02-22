#!/bin/bash

function usage {
  echo "Usage: build.sh <component> <selenium-version> <docker-version-to-output> [<additional-build-args> ]"
  echo "   Example: build.sh hub 3.0.1 local \"--build-arg MYKEY=MYVAL\""
  exit 1
}

function check_args {
	if [ -z "$1" ]
	  then
	    usage
	fi

	if [ -z "$2" ]
	  then
	    usage
	fi
	if [ -z "$3" ]
	  then
	    usage
	fi
	if [ -z "$4" ]
	  then
	    ADDITIONAL_BUILD_ARGS=""
	  else
	    ADDITIONAL_BUILD_ARGS="$4"
	fi
}

function set_variables {
	COMPONENT=$1
	SELENIUM_VERSION_INPUT=$2
	MY_VERSION=$3
}

function split_string {
  IN=$1
  arrIN=(${IN//./ })
  INDEX=$2
  echo ${arrIN[$INDEX]}
}


function parse_selenium_version {
	SELENIUM_MAJOR=$(split_string $SELENIUM_VERSION_INPUT 0)
	SELENIUM_MINOR=$(split_string $SELENIUM_VERSION_INPUT 1)
	SELENIUM_PATCH=$(split_string $SELENIUM_VERSION_INPUT 2)

	function selenium_usage {
		 echo "invalid selenium version. expected <major>.<minor>.<patch> e.g. 3.2.1"
		 exit 1
	}

	if [ -z "$SELENIUM_MAJOR" ]
		then
		   selenium_usage
	fi

	if [ -z "$SELENIUM_MINOR" ]
		then
		   selenium_usage
	fi

	if [ -z "$SELENIUM_PATCH" ]
		then
		   selenium_usage
	fi
}

check_args "$@"
set_variables "$@"
parse_selenium_version "$@"

BUILD_ARGS="$ADDITIONAL_BUILD_ARGS --build-arg SELENIUM_MAJOR_VERSION=$SELENIUM_MAJOR --build-arg SELENIUM_MINOR_VERSION=$SELENIUM_MINOR --build-arg SELENIUM_PATCH_VERSION=$SELENIUM_PATCH"

BUILD_ARGS="$BUILD_ARGS" VERSION=$MY_VERSION make build $COMPONENT
