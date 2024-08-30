#!/bin/bash

# Specify the output file for the CHANGELOG
CHART_DIR="./charts/selenium-grid"
CHANGELOG_FILE="./charts/selenium-grid/CHANGELOG.md"
TAG_PATTERN="selenium-grid"
DEFAULT_TAG="trunk"
SET_TAG=${1:-$(git rev-parse --abbrev-ref HEAD)}

# Get current chart app version
CHART_APP_VERSION=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 cat | grep ^appVersion | cut -d ':' -f 2 | tr -d '[:space:]')

# Generate the changelog
generate_changelog() {
  # Get a list of tags sorted by commit date
  tags=($(git tag --sort=committerdate | grep "^$TAG_PATTERN"))
  tags_size=${#tags[@]}

  CURRENT_CHART_VERSION=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 cat | grep ^version | cut -d ':' -f 2 | tr -d '[:space:]')

  # Check if there are tags
  if [ ${#tags[@]} -eq 0 ]; then
    commit_range="$DEFAULT_TAG"
    change_title="${TAG_PATTERN}-${CURRENT_CHART_VERSION}"
  elif [ ${#tags[@]} -eq 1 ] || [ "$SET_TAG" = "$DEFAULT_TAG" ]; then
    previous_tag="${tags[$tags_size - 1]}"
    current_tag="$DEFAULT_TAG"
    commit_range="${previous_tag}..origin/${current_tag}"
    change_title="${TAG_PATTERN}-${CURRENT_CHART_VERSION}"
  else
    previous_tag="${tags[$tags_size - 2]}"
    current_tag="${tags[$tags_size - 1]}"
    commit_range="${previous_tag}..origin/${current_tag}"
    change_title="$current_tag"
  fi

  echo "Generating changelog for ${change_title}"

  # Get the changes for each section (Added, Removed, Fixed, Changed)
  image_tag_changes=$(echo "Chart is using image tag $CHART_APP_VERSION" | sed -e 's/^/- /')
  k8s_versions_tested=$(echo "Chart is tested on Kubernetes versions: $(cat .github/workflows/helm-chart-test.yml | grep -oP "k8s-version: '\Kv.*(?=')" | tr '\n' ',' | sed s/,/,\ /g)" | sed -e 's/^/- /')
  docker_versions_tested=$(echo "Chart is tested on container runtime Docker versions: $(cat .github/workflows/helm-chart-test.yml | grep -oP "docker-version: '\K.*(?=')" | tr '\n' ',' | sed s/,/,\ /g)" | sed -e 's/^/- /')
  helm_versions_tested=$(echo "Chart is tested on Helm versions: $(cat .github/workflows/helm-chart-test.yml | grep -oP "helm-version: '\Kv.*(?=')" | tr '\n' ',' | sed s/,/,\ /g)" | sed -e 's/^/- /')
  added_changes=$(git log --pretty=format:"[\`%h\`](http://github.com/seleniumhq/docker-selenium/commit/%H) - %s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iE "\- feat|\- add" | sed -e 's/^/- /')
  removed_changes=$(git log --pretty=format:"[\`%h\`](http://github.com/seleniumhq/docker-selenium/commit/%H) - %s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iE "\- remove|\- deprecate|\- delete" | sed -e 's/^/- /')
  fixed_changes=$(git log --pretty=format:"[\`%h\`](http://github.com/seleniumhq/docker-selenium/commit/%H) - %s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iE "\- fix|\- bug" | sed -e 's/^/- /')
  changed_changes=$(git log --pretty=format:"[\`%h\`](http://github.com/seleniumhq/docker-selenium/commit/%H) - %s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iEv "\- feat|\- add|\- remove|\- deprecate|\- delete|\- fix|\- bug" | sed -e 's/^/- /')

  # Create a temporary file
  temp_file=$(mktemp)

  # Write to the temporary file
  echo "## :heavy_check_mark: ${change_title}" >>"$temp_file"
  echo "" >>"$temp_file"
  echo "$image_tag_changes" >>"$temp_file"
  echo "$k8s_versions_tested" >>"$temp_file"
  echo "$docker_versions_tested" >>"$temp_file"
  echo "$helm_versions_tested" >>"$temp_file"
  echo "" >>"$temp_file"

  if [ -n "$added_changes" ]; then
    echo "### Added" >>"$temp_file"
    echo "$added_changes" >>"$temp_file"
    echo "" >>"$temp_file"
  fi

  if [ -n "$removed_changes" ]; then
    echo "### Removed" >>"$temp_file"
    echo "$removed_changes" >>"$temp_file"
    echo "" >>"$temp_file"
  fi

  if [ -n "$fixed_changes" ]; then
    echo "### Fixed" >>"$temp_file"
    echo "$fixed_changes" >>"$temp_file"
    echo "" >>"$temp_file"
  fi

  if [ -n "$changed_changes" ]; then
    echo "### Changed" >>"$temp_file"
    echo "$changed_changes" >>"$temp_file"
    echo "" >>"$temp_file"
  fi

  # Create chart_release_notes.md
  release_notes_file="$CHART_DIR/RELEASE_NOTES.md"
  chart_description=$(find . \( -type d -name .git -prune \) -o -type f -wholename '*/selenium-grid/Chart.yaml' -print0 | xargs -0 cat | grep ^description | cut -d ':' -f 2)
  echo "$chart_description" >"$release_notes_file"
  echo "" >>"$release_notes_file"
  cat $temp_file >>"$release_notes_file"
  echo "Generated release notes at $release_notes_file"

  # Append the existing content of CHANGELOG to the temporary file
  cat "$CHANGELOG_FILE" >>"$temp_file"

  if [[ $(cat $CHANGELOG_FILE) == *"${change_title}"* ]]; then
    echo "Changelog already generated for ${change_title}"
    rm -rf "$temp_file"
    exit 0
  else
    # Overwrite CHANGELOG with the content of the temporary file
    mv "$temp_file" "$CHANGELOG_FILE"
  fi

}

# Run the function to generate the changelog
generate_changelog

echo "Changelog generated successfully at $CHANGELOG_FILE"

echo -e "true" >/tmp/selenium_chart_release
