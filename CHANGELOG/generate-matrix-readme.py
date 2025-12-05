#!/usr/bin/env python3
import os
import re
import shutil
from collections import defaultdict


def archive_old_versions():
    """Move old Grid versions to archived folder, keeping only the latest version."""
    # Find all Grid version directories in current directory
    current_versions = []
    for item in os.listdir('.'):
        if os.path.isdir(item) and re.match(r'\d+\.\d+\.\d+', item):
            current_versions.append(item)

    if len(current_versions) <= 1:
        print(f"Only {len(current_versions)} version(s) found in current directory. Nothing to archive.")
        return

    # Sort versions to find the latest
    sorted_versions = sorted(current_versions, key=lambda x: [int(i) for i in x.split('.')], reverse=True)
    latest_version = sorted_versions[0]
    versions_to_archive = sorted_versions[1:]

    print(f"Latest version: {latest_version}")
    print(f"Versions to archive: {', '.join(versions_to_archive)}")

    # Create archived directory if it doesn't exist
    if not os.path.exists('archived'):
        os.makedirs('archived')
        print("Created 'archived' directory")

    # Move old versions to archived
    for version in versions_to_archive:
        source = version
        destination = os.path.join('archived', version)

        if os.path.exists(destination):
            print(f"  Skipping {version} (already exists in archived)")
        else:
            shutil.move(source, destination)
            print(f"  Moved {version} to archived/")


def scan_changelog():
    matrix = defaultdict(lambda: defaultdict(set))

    # Scan both current directory and archived directory
    directories_to_scan = ['.']
    if os.path.exists('archived') and os.path.isdir('archived'):
        directories_to_scan.append('archived')

    for base_dir in directories_to_scan:
        for grid_version in os.listdir(base_dir):
            version_path = os.path.join(base_dir, grid_version)
            if not os.path.isdir(version_path) or not re.match(r'\d+\.\d+\.\d+', grid_version):
                continue

            for file in os.listdir(version_path):
                if file.endswith('.md'):
                    # Match both regular browser files (e.g., chrome_100.md) and chrome-for-testing files
                    match = re.match(r'([\w-]+)_(\d+)\.md', file)
                    if match:
                        browser, version = match.groups()
                        matrix[grid_version][browser].add(int(version))

    return matrix


def generate_readme(matrix):
    all_browsers = set()
    all_versions = defaultdict(set)

    for grid_versions in matrix.values():
        for browser, versions in grid_versions.items():
            all_browsers.add(browser)
            all_versions[browser].update(versions)

    browsers = sorted(all_browsers)
    grid_versions = sorted(matrix.keys(), key=lambda x: [int(i) for i in x.split('.')], reverse=True)

    # Determine which grid versions are in archived directory
    latest_version = grid_versions[0] if grid_versions else None
    archived_versions = set()
    if os.path.exists('archived') and os.path.isdir('archived'):
        for version in os.listdir('archived'):
            if os.path.isdir(os.path.join('archived', version)) and re.match(r'\d+\.\d+\.\d+', version):
                archived_versions.add(version)

    # Separate latest and archived versions
    latest_grid_versions = [v for v in grid_versions if v not in archived_versions]
    archived_grid_versions = [v for v in grid_versions if v in archived_versions]

    readme = """# Selenium Grid x Browser Version Matrix

This matrix shows available Docker images with packaged Selenium Grid and browser versions. It helps users quickly identify which image tags to pull for their testing needs.

**Motivation**: To supply the latest Selenium Grid core version with new functionality while keeping users able to use it for testing purposes like cross-browser testing or pinning a browser version due to limited support or issues at specific browser versions. We deliver Docker images for Node and Standalone with packaging both Grid and specific driver/browser versions. Users just find the image tag, pull the image they need and start their tests.

**How to read**: Each ✓ links to detailed changelog information for that specific browser version in the corresponding Grid release. Latest versions appear first (descending order).

**Note**: We don't have full testing to ensure every combination of Grid and browser version will function fully as expected. Users need to evaluate and make their own decisions based on their testing requirements.

"""

    # Generate tables for latest Grid versions
    if latest_grid_versions:
        readme += "## Latest Grid Version\n\n"

        for browser in browsers:
            all_browser_versions = sorted(all_versions[browser], reverse=True)
            # Format browser name: replace hyphens with spaces and title case
            browser_display = browser.replace('-', ' ').title()

            # Find latest grid versions that have this browser
            grid_versions_with_browser = [
                gv for gv in latest_grid_versions if browser in matrix[gv] and matrix[gv][browser]
            ]

            if not grid_versions_with_browser:
                continue

            # Filter to only include browser versions that exist in at least one of these grid versions
            versions_to_show = [
                v for v in all_browser_versions if any(v in matrix[gv][browser] for gv in grid_versions_with_browser)
            ]

            if not versions_to_show:
                continue

            readme += f"### {browser_display}\n\n"
            readme += "| Grid Version | " + " | ".join(map(str, versions_to_show)) + " |\n"
            readme += "|" + "-" * 14 + "|" + "|".join(["-" * 4 for _ in versions_to_show]) + "|\n"

            for grid_version in grid_versions_with_browser:
                row = f"| {grid_version} |"
                for version in versions_to_show:
                    if version in matrix[grid_version][browser]:
                        mark = f" [✓]({grid_version}/{browser}_{version}.md) "
                    else:
                        mark = "   "
                    row += f"{mark}|"
                readme += row + "\n"
            readme += "\n"

    # Generate tables for archived Grid versions
    if archived_grid_versions:
        readme += "## Archived Grid Versions\n\n"

        for browser in browsers:
            all_browser_versions = sorted(all_versions[browser], reverse=True)
            # Format browser name: replace hyphens with spaces and title case
            browser_display = browser.replace('-', ' ').title()

            # Find archived grid versions that have this browser
            grid_versions_with_browser = [
                gv for gv in archived_grid_versions if browser in matrix[gv] and matrix[gv][browser]
            ]

            if not grid_versions_with_browser:
                continue

            # Filter to only include browser versions that exist in at least one of these grid versions
            versions_to_show = [
                v for v in all_browser_versions if any(v in matrix[gv][browser] for gv in grid_versions_with_browser)
            ]

            if not versions_to_show:
                continue

            readme += f"### {browser_display}\n\n"
            readme += "| Grid Version | " + " | ".join(map(str, versions_to_show)) + " |\n"
            readme += "|" + "-" * 14 + "|" + "|".join(["-" * 4 for _ in versions_to_show]) + "|\n"

            for grid_version in grid_versions_with_browser:
                row = f"| {grid_version} |"
                for version in versions_to_show:
                    if version in matrix[grid_version][browser]:
                        mark = f" [✓](archived/{grid_version}/{browser}_{version}.md) "
                    else:
                        mark = "   "
                    row += f"{mark}|"
                readme += row + "\n"
            readme += "\n"

    return readme


if __name__ == "__main__":
    os.chdir('./CHANGELOG')

    # Step 1: Archive old versions
    print("Step 1: Archiving old Grid versions...")
    archive_old_versions()
    print()

    # Step 2: Scan changelog directories
    print("Step 2: Scanning changelog directories...")
    matrix = scan_changelog()
    print(f"Found {len(matrix)} Grid version(s)")
    print()

    # Step 3: Generate README
    print("Step 3: Generating README.md...")
    readme_content = generate_readme(matrix)

    with open('README.md', 'w') as f:
        f.write(readme_content)

    print("README.md generated successfully!")
