#!/bin/bash

# Specify the output file for the CHANGELOG
CHART_DIR="./charts/selenium-grid"
CHANGELOG_FILE="./charts/selenium-grid/CHANGELOG.md"
TAG_PATTERN="selenium-grid"

# Get current chart app version
CHART_APP_VERSION=$(find . \( -type d -name .git -prune \) -o -type f -name 'Chart.yaml' -print0 | xargs -0 cat | grep ^appVersion | cut -d ':' -f 2 | tr -d '[:space:]')

# Generate the changelog
generate_changelog() {
    # Get a list of tags sorted by commit date
    tags=($(git tag --sort=committerdate | grep "^$TAG_PATTERN"))
    tags_size=${#tags[@]}

    # Check if there are tags
    if [ ${#tags[@]} -eq 0 ]; then
        commit_range="HEAD"
    elif [ ${#tags[@]} -eq 1 ]; then
        previous_tag="${tags[$tags_size-1]}"
        current_tag="HEAD"
        commit_range="${previous_tag}..${current_tag}"
    else
        previous_tag="${tags[$tags_size-2]}"
        current_tag="${tags[$tags_size-1]}"
        commit_range="${previous_tag}..${current_tag}"
    fi

    # Get the changes for each section (Added, Removed, Fixed, Changed)
    image_tag_changes=$(echo "Chart is using image tag $CHART_APP_VERSION" | sed -e 's/^/- /')
    k8s_versions_tested=$(echo "Chart is tested on Kubernetes versions: $(cat .github/workflows/helm-chart-test.yml | grep -oP "k8s-version: '\Kv.*(?=')" | tr '\n' ',')")
    added_changes=$(git log --pretty=format:"%s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iE "^feat|^add" | sed -e 's/^/- /')
    removed_changes=$(git log --pretty=format:"%s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iE "^remove|^deprecate|^delete" | sed -e 's/^/- /')
    fixed_changes=$(git log --pretty=format:"%s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iE "^fix|^bug" | sed -e 's/^/- /')
    changed_changes=$(git log --pretty=format:"%s :: %an" "$commit_range" -- "$CHART_DIR" | grep -iEv "^feat|^add|^remove|^deprecate|^delete|^fix|^bug" | sed -e 's/^/- /')

    if [[ $(cat $CHANGELOG_FILE) == *"${current_tag}"* ]]; then
        echo "Changelog already generated for ${current_tag}"
        exit 0
    fi

    # Create a temporary file
    temp_file=$(mktemp)

    # Write to the temporary file
    echo "## :heavy_check_mark: ${current_tag}" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "$image_tag_changes" >> "$temp_file"
    echo "$k8s_versions_tested" >> "$temp_file"
    echo "" >> "$temp_file"

    if [ -n "$added_changes" ]; then
        echo "### Added" >> "$temp_file"
        echo "$added_changes" >> "$temp_file"
        echo "" >> "$temp_file"
    fi

    if [ -n "$removed_changes" ]; then
        echo "### Removed" >> "$temp_file"
        echo "$removed_changes" >> "$temp_file"
        echo "" >> "$temp_file"
    fi

    if [ -n "$fixed_changes" ]; then
        echo "### Fixed" >> "$temp_file"
        echo "$fixed_changes" >> "$temp_file"
        echo "" >> "$temp_file"
    fi

    if [ -n "$changed_changes" ]; then
        echo "### Changed" >> "$temp_file"
        echo "$changed_changes" >> "$temp_file"
        echo "" >> "$temp_file"
    fi

    # Append the existing content of CHANGELOG to the temporary file
    cat "$CHANGELOG_FILE" >> "$temp_file"

    # Overwrite CHANGELOG with the content of the temporary file
    mv "$temp_file" "$CHANGELOG_FILE"
}

# Run the function to generate the changelog
generate_changelog

echo "Changelog generated successfully at $CHANGELOG_FILE"
