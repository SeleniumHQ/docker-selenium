#!/usr/bin/env python3
import re
from pathlib import Path

import yaml

# Minimum browser versions to include in workflows
MIN_CHROME_VERSION = 95
MIN_FIREFOX_VERSION = 98
MIN_EDGE_VERSION = 114
MIN_CFT_VERSION = 113


def read_browser_matrix(file_path, min_chrome_version, min_firefox_version, min_edge_version, min_cft_version):
    """Read the browser matrix YAML file and extract browser versions.

    Args:
        file_path: Path to the browser matrix YAML file
        min_chrome_version: Minimum Chrome version to include
        min_firefox_version: Minimum Firefox version to include
        min_edge_version: Minimum Edge version to include
        min_cft_version: Minimum Chrome for Testing version to include
    """
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)

    chrome_versions = []
    firefox_versions = []
    edge_versions = []
    cft_versions = []

    browsers = data.get('matrix', {}).get('browser', {})

    for version, details in browsers.items():
        version_int = int(version)

        # Check for Chrome versions (not null or empty) and above minimum
        chrome_version = details.get('CHROME_VERSION')
        if (
            chrome_version
            and chrome_version != 'null'
            and str(chrome_version).strip()
            and version_int >= min_chrome_version
        ):
            chrome_versions.append(version_int)

        # Check for Firefox versions (not null or empty) and above minimum
        firefox_version = details.get('FIREFOX_VERSION')
        if (
            firefox_version
            and firefox_version != 'null'
            and str(firefox_version).strip()
            and version_int >= min_firefox_version
        ):
            firefox_versions.append(version_int)

        # Check for Edge versions (not null or empty) and above minimum
        edge_version = details.get('EDGE_VERSION')
        if edge_version and edge_version != 'null' and str(edge_version).strip() and version_int >= min_edge_version:
            edge_versions.append(version_int)

        # Check for Chrome for Testing versions (not null or empty) and above minimum
        cft_version = details.get('CFT_VERSION')
        if cft_version and cft_version != 'null' and str(cft_version).strip() and version_int >= min_cft_version:
            cft_versions.append(version_int)

    # Sort versions in ascending order
    chrome_versions.sort()
    firefox_versions.sort()
    edge_versions.sort()
    cft_versions.sort()

    # Exclude the last (newest) version from each list
    # if chrome_versions:
    #     chrome_versions = chrome_versions[:-1]
    # if firefox_versions:
    #     firefox_versions = firefox_versions[:-1]
    # if edge_versions:
    #     edge_versions = edge_versions[:-1]
    # if cft_versions:
    #     cft_versions = cft_versions[:-1]

    return chrome_versions, firefox_versions, edge_versions, cft_versions


def format_version_list(versions):
    """Format version list as a string like '[95, 96, 97, ...]'"""
    return str(versions)


def update_workflow_file(workflow_file, versions_list):
    """Update the workflow file with new version list for browser-versions.default only."""
    with open(workflow_file, 'r') as f:
        lines = f.readlines()

    updated_lines = []
    in_browser_versions = False

    for i, line in enumerate(lines):
        # Check if we're in the browser-versions section
        if re.match(r'^(\s*)browser-versions:\s*$', line):
            in_browser_versions = True
            updated_lines.append(line)
        elif in_browser_versions and re.match(r'^(\s*)default:\s*', line):
            # We found the default line within browser-versions section
            indent_match = re.match(r'^(\s*)default:', line)
            indent = indent_match.group(1) if indent_match else ''
            # Replace the line with new version list
            updated_lines.append(f"{indent}default: '{versions_list}'\n")
            in_browser_versions = False  # Reset flag after updating
        elif in_browser_versions and re.match(r'^(\s+)(description|required|type):\s*', line):
            # Still within browser-versions section, continue
            updated_lines.append(line)
        elif in_browser_versions and re.match(r'^(\s*)[a-zA-Z-]+:\s*', line) and not re.match(r'^(\s+)', line):
            # We've moved to another top-level field, reset the flag
            in_browser_versions = False
            updated_lines.append(line)
        else:
            updated_lines.append(line)

    with open(workflow_file, 'w') as f:
        f.writelines(updated_lines)


def main():
    # Paths
    browser_matrix_file = Path('tests/build-backward-compatible/browser-matrix.yml')
    chrome_workflow_file = Path('.github/workflows/release-chrome-versions.yml')
    firefox_workflow_file = Path('.github/workflows/release-firefox-versions.yml')
    edge_workflow_file = Path('.github/workflows/release-edge-versions.yml')
    cft_workflow_file = Path('.github/workflows/release-chrome-for-testing-versions.yml')

    # Read browser versions with minimum version filtering
    chrome_versions, firefox_versions, edge_versions, cft_versions = read_browser_matrix(
        browser_matrix_file,
        min_chrome_version=MIN_CHROME_VERSION,
        min_firefox_version=MIN_FIREFOX_VERSION,
        min_edge_version=MIN_EDGE_VERSION,
        min_cft_version=MIN_CFT_VERSION,
    )

    # Format version lists
    chrome_list = format_version_list(chrome_versions)
    firefox_list = format_version_list(firefox_versions)
    edge_list = format_version_list(edge_versions)
    cft_list = format_version_list(cft_versions)

    print(f"Chrome versions: {chrome_list}")
    print(f"Firefox versions: {firefox_list}")
    print(f"Edge versions: {edge_list}")
    print(f"Chrome for Testing versions: {cft_list}")

    # Update workflow files
    if chrome_workflow_file.exists():
        update_workflow_file(chrome_workflow_file, chrome_list)
        print(f"Updated {chrome_workflow_file}")

    if firefox_workflow_file.exists():
        update_workflow_file(firefox_workflow_file, firefox_list)
        print(f"Updated {firefox_workflow_file}")

    if edge_workflow_file.exists():
        update_workflow_file(edge_workflow_file, edge_list)
        print(f"Updated {edge_workflow_file}")

    if cft_workflow_file.exists():
        update_workflow_file(cft_workflow_file, cft_list)
        print(f"Updated {cft_workflow_file}")


if __name__ == '__main__':
    main()
