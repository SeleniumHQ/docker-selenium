import os
import re
import yaml
from collections import OrderedDict

def extract_variables_from_shell_scripts(directory_path):
    variables = OrderedDict()
    for root, _, files in os.walk(directory_path):
        files.sort()
        for file in files:
            if file.endswith(".sh"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                    pattern = r'\b(SE_[A-Za-z0-9_]+)\b'
                    matches = re.findall(pattern, content)
                    for var in matches:
                        variables[var] = ""
                except Exception as e:
                    print(f"Error reading file {file_path}: {e}")
    return variables

def extract_variables_from_dockerfiles(directory_path):
    variables = OrderedDict()
    for root, _, files in os.walk(directory_path):
        files.sort()
        for file in files:
            if file.startswith("Dockerfile"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                    pattern = r'\b(SE_[A-Za-z0-9_]+)\s*=\s*["\']([^"\']*)["\']'
                    matches = re.findall(pattern, content)
                    for var, value in matches:
                        variables[var] = value
                except Exception as e:
                    print(f"Error reading file {file_path}: {e}")
    return variables

def combine_dictionaries(dict1, dict2):
    combined_dict = OrderedDict(dict1)
    combined_dict.update(dict2)
    combined_dict = dict(sorted(combined_dict.items()))
    return combined_dict

def read_description_yaml(file_path):
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)
        return data if data is not None else []

def update_description_yaml(description, combined_vars):
    for var, value in combined_vars.items():
        if not any(item['name'] == var for item in description):
            description.append({'name': var, 'default': value, 'description': '', 'cli': ''})
    return description

def dump_to_yaml(data, file_path):
    with open(file_path, 'w') as file:
        yaml.dump(data, file, default_flow_style=False, sort_keys=False, allow_unicode=True, encoding='utf-8')

def write_value_file(combined_vars, file_path):
    data = [{'name': key, 'default': value} for key, value in combined_vars.items()]
    dump_to_yaml(data, file_path)

def write_description_file(description, file_path):
    data = [{'name': item['name'], 'description': item['description'], 'cli': item['cli']} for item in description]
    dump_to_yaml(data, file_path)

# Example usage
directory_path = os.getcwd()
description_file = f"{os.getcwd()}/scripts/generate_list_env_vars/description.yaml"
value_file = f"{os.getcwd()}/scripts/generate_list_env_vars/value.yaml"
output_file = f"{os.getcwd()}/ENV_VARIABLES.md"

shell_variables = extract_variables_from_shell_scripts(directory_path)
dockerfile_variables = extract_variables_from_dockerfiles(directory_path)
combined_variables = combine_dictionaries(shell_variables, dockerfile_variables)

description = read_description_yaml(description_file)
updated_description = update_description_yaml(description, combined_variables)

dump_to_yaml(updated_description, description_file)
write_value_file(combined_variables, value_file)
write_description_file(updated_description, description_file)

print(f"Updated description saved to {description_file}")
print(f"Value file saved to {value_file}")

def render_markdown_table(description, values):
    table =  "| ENV variable | Default value | Description | CLI option represent |\n"
    table += "|--------------|---------------|-------------|----------------------|\n"

    value_dict = {item['name']: item['default'] for item in values}

    for item in description:
        name = item['name']
        default = value_dict.get(name, "")
        des = item.get('description', "")
        cli = item.get('cli', "")
        table += f"| {name} | {default} | {des} | {cli} |\n"

    return table

def write_markdown_to_file(markdown, file_path):
    with open(file_path, 'w') as file:
        file.write(markdown)

description = read_description_yaml(description_file)
values = read_description_yaml(value_file)

markdown_table = render_markdown_table(description, values)
write_markdown_to_file(markdown_table, output_file)

print(f"Markdown table saved to {output_file}")
