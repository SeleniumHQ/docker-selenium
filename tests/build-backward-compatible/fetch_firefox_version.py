import re
from collections import defaultdict

import requests
import yaml

local_file = 'tests/build-backward-compatible/firefox-matrix.yml'


def fetch_firefox_versions():
    url = 'https://ftp.mozilla.org/pub/firefox/releases/'
    resp = requests.get(url)
    resp.raise_for_status()
    # Extract version numbers like 136.0.4/
    versions = re.findall(r'(\d+\.\d+(?:\.\d+)?)/', resp.text)
    # Filter out pre-releases
    versions = [v for v in versions if not any(x in v for x in ['esr', 'rc', 'b', 'a'])]
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
    # Build YAML structure
    yaml_struct = {'matrix': {'browser': {}}}
    for major, version in sorted(result.items(), key=lambda x: int(x[0]), reverse=True):
        yaml_struct['matrix']['browser'][str(major)] = {'FIREFOX_VERSION': version}
    with open(local_file, 'w') as file:
        yaml.dump(yaml_struct, file, default_flow_style=False, sort_keys=False)


fetch_firefox_versions()
