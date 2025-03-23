import requests
import yaml
from collections import OrderedDict

# URLs of the source YAML files
chrome_url = 'https://raw.githubusercontent.com/NDViet/google-chrome-stable/refs/heads/main/browser-matrix.yml'
edge_url = 'https://raw.githubusercontent.com/NDViet/microsoft-edge-stable/refs/heads/main/browser-matrix.yml'

# Local YAML file to update
local_file = 'tests/build-backward-compatible/browser-matrix.yml'

def fetch_yaml(url):
    response = requests.get(url)
    response.raise_for_status()
    return yaml.load(response.text, Loader=yaml.SafeLoader)

def merge_dicts(dict1, dict2):
    for key, value in dict2.items():
        if key in dict1 and isinstance(dict1[key], dict) and isinstance(value, dict):
            merge_dicts(dict1[key], value)
        elif key in dict1 and '_PACKAGE_' not in key:
            dict1[key] = value if value is not None else ""

def update_local_yaml(local_data, source_data):
    updated = False
    for version, details in source_data['matrix']['browser'].items():
        if version in local_data['matrix']['browser']:
            original_details = local_data['matrix']['browser'][version]
            for key in details:
                if key in original_details and '_PACKAGE_' not in key:
                    original_details[key] = details[key] if details[key] is not None else ""
                    updated = True
            merge_dicts(original_details, details)
    return updated

def main():
    # Fetch source YAML data
    chrome_data = fetch_yaml(chrome_url)
    edge_data = fetch_yaml(edge_url)

    # Load local YAML data
    with open(local_file, 'r') as file:
        local_data = yaml.load(file, Loader=yaml.SafeLoader)

    # Update local YAML data with source data
    updated = update_local_yaml(local_data, chrome_data)
    updated |= update_local_yaml(local_data, edge_data)

    # Save updated local YAML data
    if updated:
        with open(local_file, 'w') as file:
            yaml.dump(local_data, file, default_flow_style=False, sort_keys=False)
        print("Local YAML file updated.")
    else:
        print("No updates needed.")

if __name__ == '__main__':
    main()
