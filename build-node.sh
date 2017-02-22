#!/bin/bash

function usage {
  echo "Usage: build-node.sh <browser> <browser-version> <webdriver-version> <selenium-version> [<docker-version-to-output>]"
  echo "   Example: build-node.sh firefox 46.0.1 0.14.0 3.0.1 0.1.0"
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
	    usage
	fi
	if [ -z "$5" ]
	  then
	    OUTPUT_VERSION=local
	  else
	    OUTPUT_VERSION=$5
	fi
}

function set_variables {
	BROWSER_TYPE=$1
	BROWSER_VERSION=$2
	DRIVER_VALUE=$3
	SELENIUM_VERSION=$4
}

function check_browser {
	EXPECTED_FIREFOX=firefox
	EXPECTED_CHOME=chrome
	
	if [ "${BROWSER_TYPE,,}" = "${EXPECTED_FIREFOX,,}" ]; then
  	VERSION_KEY=FIREFOX_VERSION
	elif [ "${BROWSER_TYPE,,}" = "${EXPECTED_CHOME,,}" ]; then
  	VERSION_KEY=CHROME_VERSION
  else
  	echo "Invalid browser type. Only firefox and chrome are supported."
  	exit 1
	fi
}

function check_web_driver {
	EXPECTED_FIREFOX=firefox
	EXPECTED_CHOME=chrome
	
	if [ "${BROWSER_TYPE,,}" = "${EXPECTED_FIREFOX,,}" ]; then
  	DRIVER_KEY=GECKODRIVER_VERSION
	elif [ "${BROWSER_TYPE,,}" = "${EXPECTED_CHOME,,}" ]; then
  	DRIVER_KEY=CHROME_DRIVER_VERSION
	fi
}


check_args "$@"
set_variables "$@"
check_browser "$@"
check_web_driver "$@"

BUILD_ARGS="--build-arg $VERSION_KEY=$BROWSER_VERSION --build-arg $DRIVER_KEY=$DRIVER_VALUE"

./build.sh $BROWSER_TYPE $SELENIUM_VERSION $OUTPUT_VERSION "$BUILD_ARGS"
