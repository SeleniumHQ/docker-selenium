#!/usr/bin/env bash

LATEST_TAG=$1
NEXT_TAG=$2
LATEST_DATE=$(echo ${LATEST_TAG} | sed 's/.*-//')
NEXT_DATE=$(echo ${NEXT_TAG} | sed 's/.*-//')
latest_chart_app_version=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 cat | grep ^appVersion | cut -d ':' -f 2 | tr -d '[:space:]')
FFMPEG_TAG_PREV_VERSION=$(grep FFMPEG_TAG_PREV_VERSION Makefile | sed 's/.*,\([^)]*\))/\1/p' | head -n 1)
FFMPEG_TAG_VERSION=$(grep FFMPEG_TAG_VERSION Makefile | sed 's/.*,\([^)]*\))/\1/p' | head -n 1)
KEDA_TAG_PREV_VERSION=$(grep KEDA_TAG_PREV_VERSION Makefile | sed 's/.*,\([^)]*\))/\1/p' | head -n 1)
KEDA_TAG_VERSION=$(grep KEDA_TAG_VERSION Makefile | sed 's/.*,\([^)]*\))/\1/p' | head -n 1)

echo -e "\033[0;32m Updating tag displayed in docs and files...\033[0m"
echo -e "\033[0;32m LATEST_TAG -> ${LATEST_TAG}\033[0m"
echo -e "\033[0;32m NEXT_TAG -> ${NEXT_TAG}\033[0m"

# If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
find . \( -type d -name .git -prune \) -o -type f ! -name 'CHANGELOG.md' -print0 | xargs -0 sed -i "s/${FFMPEG_TAG_PREV_VERSION}/${FFMPEG_TAG_VERSION}/g"

# If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
find . \( -type d -name .git -prune \) -o -type f ! -name 'CHANGELOG.md' -print0 | xargs -0 sed -i "s/${KEDA_TAG_PREV_VERSION}/${KEDA_TAG_VERSION}/g"

# multiple-nodes-platform-version.yaml (and its test copy) pin per-Chrome-version
# image tags (146.0-<date>, 145.0-<date>, ...) dated independently of the Grid
# release, by their own browser-version release process - not by this script.
# Their date happens to collide with the Grid release's date often enough that
# the bare-date pass below would otherwise rewrite them to a date that was
# never actually built for those versions.
#
# deploy.yml's only tag-shaped strings are inside one comment narrating a past
# incident by its exact values (why LATEST_TAG resolution moved to `git
# describe`). Every later release's LATEST_TAG eventually collides with one of
# those literals, so without this exclusion the comment keeps getting quietly
# rewritten into a false account of its own history.
TAG_REWRITE_SKIP_PATHS="( -path ./charts/selenium-grid/multiple-nodes-platform-version.yaml -o -path ./tests/charts/ci/multiple-nodes-platform-version-values.yaml -o -path ./.github/workflows/deploy.yml )"

# If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
find . \( -type d -name .git -prune -o -type d -name 'CHANGELOG' -prune -o $TAG_REWRITE_SKIP_PATHS -prune \) -o -type f ! -name 'CHANGELOG.md' -print0 | xargs -0 sed -i "s/${LATEST_TAG}/${NEXT_TAG}/g"

if [[ "$NEXT_TAG" == "latest" ]] || [[ "$NEXT_TAG" == "nightly" ]]; then
  # If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
  FFMPEG_LATEST_TAG=${FFMPEG_TAG_VERSION}-${LATEST_DATE}
  KEDA_LATEST_TAG=${KEDA_TAG_VERSION}-${LATEST_DATE}
  find . \( -type d -name .git -prune \) -o -type f ! -name 'CHANGELOG.md' -print0 | xargs -0 sed -i "s/${KEDA_LATEST_TAG}/${NEXT_TAG}/g"
  find . \( -type d -name .git -prune \) -o -type f ! -name 'CHANGELOG.md' -print0 | xargs -0 sed -i "s/${FFMPEG_LATEST_TAG}/${NEXT_TAG}/g"
fi

echo -e "\033[0;32m Updating date used in some docs and files...\033[0m"
echo -e "\033[0;32m LATEST_DATE -> ${LATEST_DATE}\033[0m"
echo -e "\033[0;32m NEXT_DATE -> ${NEXT_DATE}\033[0m"

# If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
find . \( -type d -name .git -prune -o -type d -name 'CHANGELOG' -prune -o $TAG_REWRITE_SKIP_PATHS -prune \) -o -type f ! -name 'CHANGELOG.md' -print0 | xargs -0 sed -i "s/${LATEST_DATE}/${NEXT_DATE}/g"

# #3274: the whole-tree sed above only matches when ${LATEST_TAG} is the exact
# string still sitting in these files. Once a wrong LATEST_TAG - or anything
# else - makes it miss once, every later release looks for a tag that was
# never embedded here and silently keeps shipping the old default forever.
# Fail loudly instead, so a release can't finish with stale chart defaults.
echo -e "\033[0;32m Verifying the chart's default image tags were updated...\033[0m"
values_file=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/values.yaml' -print -quit)
if [ -z "$values_file" ]; then
  echo -e "\033[0;31m Could not find charts/selenium-grid/values.yaml.\033[0m" >&2
  exit 1
fi
for field in imageTag nodesImageTag; do
  if ! grep -qE "^\s*${field}: ${NEXT_TAG}\$" "$values_file"; then
    echo -e "\033[0;31m ${values_file}'s ${field} was not updated to ${NEXT_TAG}. LATEST_TAG (${LATEST_TAG}) probably doesn't match what's actually in the file - fix it manually before releasing.\033[0m" >&2
    exit 1
  fi
done

# Bump chart version and appVersion if next tag is different
if [ "$latest_chart_app_version" == $LATEST_TAG ] && [ "$latest_chart_app_version" != "$NEXT_TAG" ]; then
  IFS='.' read -ra latest_version_parts <<<"$LATEST_TAG"
  IFS='.' read -ra next_version_parts <<<"$NEXT_TAG"
  latest_chart_version=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 cat | grep ^version | cut -d ':' -f 2 | tr -d '[:space:]')
  IFS='.' read -ra latest_chart_version_parts <<<"$latest_chart_version"
  if [ "${latest_version_parts[0]}" != "${next_version_parts[0]}" ]; then
    ((latest_chart_version_parts[0]++))
    latest_chart_version_parts[1]=0
    latest_chart_version_parts[2]=0
  elif [ "${latest_version_parts[1]}" != "${next_version_parts[1]}" ]; then
    ((latest_chart_version_parts[1]++))
    latest_chart_version_parts[2]=0
  elif [ "${latest_version_parts[2]}" != "${next_version_parts[2]}" ]; then
    ((latest_chart_version_parts[2]++))
  fi
  next_chart_version="${latest_chart_version_parts[0]}.${latest_chart_version_parts[1]}.${latest_chart_version_parts[2]}"
  echo -e "\033[0;32m Updating chart version...\033[0m"
  echo -e "\033[0;32m LATEST_CHART_VERSION -> ${latest_chart_version}\033[0m"
  echo -e "\033[0;32m NEXT_CHART_VERSION -> ${next_chart_version}\033[0m"
  # If you want to test this locally and you are using macOS, do `brew install gnu-sed` and change `sed` for `gsed`.
  find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 sed -i "s/${latest_chart_version}/${next_chart_version}/g"
  find . \( -type d -name .git -prune \) -o -type f -wholename '*/bug_report.yml' -print0 | xargs -0 sed -i "s/${latest_chart_version}/${next_chart_version}/g"
fi

git diff | cat

echo -e "\033[0;32m Text updated...\033[0m"
