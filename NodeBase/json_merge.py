import json
import sys

json_str1 = sys.argv[1]
json_str2 = sys.argv[2]

try:
  # Parse JSON strings into dictionaries
  dict1 = json.loads(json_str1)
  dict2 = json.loads(json_str2)
  # Merge dictionaries
  merged_dict = {**dict1, **dict2}
  # Convert merged dictionary back to JSON string
  merged_json_str = json.dumps(merged_dict, separators=(',', ':'), ensure_ascii=True)
  # Print the merged JSON string
  print(merged_json_str)
except:
  # Print the first JSON string if an error occurs
  print(json_str1)
  sys.exit(1)
