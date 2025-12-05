import re
from collections import defaultdict

import requests
import yaml

local_file = 'tests/build-backward-compatible/browser-matrix.yml'


def fetch_chrome_for_testing_versions():
    # Fetch latest stable version to use as maximum version filter
    stable_url = 'https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE'
    stable_resp = requests.get(stable_url)
    stable_resp.raise_for_status()
    max_stable_version = stable_resp.text.strip()
    print(f"Latest stable version: {max_stable_version}")

    # Parse max stable version for comparison
    max_stable_parts = list(map(int, max_stable_version.split('.')))

    url = 'https://googlechromelabs.github.io/chrome-for-testing/known-good-versions.json'
    resp = requests.get(url)
    resp.raise_for_status()
    data = resp.json()

    # Extract versions from the JSON, filtering out versions higher than stable
    versions = []
    for item in data.get('versions', []):
        version = item.get('version')
        if version:
            version_parts = list(map(int, version.split('.')))
            # Only include versions <= max stable version (avoid dev/beta/canary)
            if version_parts <= max_stable_parts:
                versions.append(version)

    # Group by major version and keep the highest patch
    version_map = defaultdict(list)
    for v in versions:
        major = v.split('.')[0]
        version_map[major].append(v)

    # For each major, pick the highest version
    result = {}
    for major, vlist in version_map.items():
        vlist.sort(key=lambda s: list(map(int, s.split('.'))))
        result[major] = vlist[-1]

    # Load existing browser-matrix.yml
    with open(local_file, 'r') as file:
        yaml_struct = yaml.safe_load(file)

    # Ensure structure exists
    if 'matrix' not in yaml_struct:
        yaml_struct['matrix'] = {}
    if 'browser' not in yaml_struct['matrix']:
        yaml_struct['matrix']['browser'] = {}

    # Update with CFT_VERSION
    for major, version in sorted(result.items(), key=lambda x: int(x[0]), reverse=True):
        major_key = str(major)
        if major_key not in yaml_struct['matrix']['browser']:
            yaml_struct['matrix']['browser'][major_key] = {}
        yaml_struct['matrix']['browser'][major_key]['CFT_VERSION'] = version

    # Write back to file
    with open(local_file, 'w') as file:
        yaml.dump(yaml_struct, file, default_flow_style=False, sort_keys=False)


fetch_chrome_for_testing_versions()
