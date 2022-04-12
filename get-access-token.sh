#!/bin/sh

python3 -m venv release_sandbox
. release_sandbox/bin/activate
if [ -z "$VIRTUAL_ENV" ]; then
	echo "Virtual environment not activated."
	exit 1
fi

pip3 install cryptography
pip3 install requests
pip3 install PyJWT

export GITHUB_APP_ID=$SELENIARM_GITHUB_APP_ID
export GITHUB_INSTALLATION_ID=$SELENIARM_GITHUB_INSTALLATION_ID 
export GITHUB_APP_PEM="$SELENIARM_GITHUB_APP_PEM" 

python3 get-access-token.py
