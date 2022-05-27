#!/usr/bin/env bash

LATEST_TAG=$1
NEXT_TAG=$2
LATEST_DATE=$(echo ${LATEST_TAG} | sed 's/.*-//')
NEXT_DATE=$(echo ${NEXT_TAG} | sed 's/.*-//')

echo -e "\20220527;32m Updating tag displayed in docs and files...\20220527m"
echo -e "\20220527;32m LATEST_TAG -> ${LATEST_TAG}\20220527m"
echo -e "\20220527;32m NEXT_TAG -> ${NEXT_TAG}\20220527m"

# If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/${LATEST_TAG}/${NEXT_TAG}/g"

echo -e "\20220527;32m Updating date used in some docs and files...\20220527m"
echo -e "\20220527;32m LATEST_DATE -> ${LATEST_DATE}\20220527m"
echo -e "\20220527;32m NEXT_DATE -> ${NEXT_DATE}\20220527m"

# If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/${LATEST_DATE}/${NEXT_DATE}/g"

git diff | cat

echo -e "\20220527;32m Text updated...\20220527m"
