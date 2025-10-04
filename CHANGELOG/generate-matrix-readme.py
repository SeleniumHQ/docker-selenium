#!/usr/bin/env python3
import os
import re
from collections import defaultdict


def scan_changelog():
    matrix = defaultdict(lambda: defaultdict(set))

    for grid_version in os.listdir('.'):
        if not os.path.isdir(grid_version) or not re.match(r'\d+\.\d+\.\d+', grid_version):
            continue

        for file in os.listdir(grid_version):
            if file.endswith('.md'):
                match = re.match(r'(\w+)_(\d+)\.md', file)
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

    readme = """# Selenium Grid x Browser Version Matrix

This matrix shows available Docker images with packaged Selenium Grid and browser versions. It helps users quickly identify which image tags to pull for their testing needs.

**Motivation**: To supply the latest Selenium Grid core version with new functionality while keeping users able to use it for testing purposes like cross-browser testing or pinning a browser version due to limited support or issues at specific browser versions. We deliver Docker images for Node and Standalone with packaging both Grid and specific driver/browser versions. Users just find the image tag, pull the image they need and start their tests.

**How to read**: Each ✓ links to detailed changelog information for that specific browser version in the corresponding Grid release. Latest versions appear first (descending order).

**Note**: We don't have full testing to ensure every combination of Grid and browser version will function fully as expected. Users need to evaluate and make their own decisions based on their testing requirements.

"""

    for browser in browsers:
        versions = sorted(all_versions[browser], reverse=True)
        readme += f"## {browser.title()}\n\n"
        readme += "| Grid Version | " + " | ".join(map(str, versions)) + " |\n"
        readme += "|" + "-" * 14 + "|" + "|".join(["-" * 4 for _ in versions]) + "|\n"

        for grid_version in grid_versions:
            row = f"| {grid_version} |"
            for version in versions:
                if version in matrix[grid_version][browser]:
                    mark = f" [✓]({grid_version}/{browser}_{version}.md) "
                else:
                    mark = "   "
                row += f"{mark}|"
            readme += row + "\n"
        readme += "\n"

    return readme


if __name__ == "__main__":
    os.chdir('./CHANGELOG')
    matrix = scan_changelog()
    readme_content = generate_readme(matrix)

    with open('README.md', 'w') as f:
        f.write(readme_content)

    print("README.md generated successfully!")
