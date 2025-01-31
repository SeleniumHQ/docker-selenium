import yaml
import sys
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

def load_template(yaml_file):
    try:
        with open(yaml_file) as file:
            documents = yaml.safe_load(file)
            return documents
    except yaml.YAMLError as error:
        logger.debug("Error in configuration file: ", error)

def recursive_merge(dict1, dict2):
    for key in dict2:
        if key in dict1 and isinstance(dict1[key], dict) and isinstance(dict2[key], dict):
            recursive_merge(dict1[key], dict2[key])
        else:
            dict1[key] = dict2[key]

if __name__ == '__main__':
    # Load matrix configuration
    selenium_matrix = load_template('tests/build-backward-compatible/selenium-matrix.yml')
    cdp_matrix = load_template('tests/build-backward-compatible/cdp-matrix.yml')
    # Merge configurations into single matrix
    recursive_merge(selenium_matrix, cdp_matrix)
    matrix = selenium_matrix["matrix"]
    # Get versions from arguments
    selenium_version = sys.argv[1]
    cdp_version = int(sys.argv[2])
    browser_name = sys.argv[3]
    # Create .env with component versions
    with open('.env', 'w') as f:
      BASE_RELEASE = matrix["selenium"][selenium_version]["BASE_RELEASE"]
      BASE_VERSION = matrix["selenium"][selenium_version]["BASE_VERSION"]
      VERSION = matrix["selenium"][selenium_version]["VERSION"]
      BINDING_VERSION = matrix["selenium"][selenium_version]["BINDING_VERSION"]
      f.write(f"BASE_RELEASE={BASE_RELEASE}\n")
      f.write(f"BASE_VERSION={BASE_VERSION}\n")
      f.write(f"VERSION={VERSION}\n")
      f.write(f"BINDING_VERSION={BINDING_VERSION}\n")
      if browser_name == "firefox" or browser_name == "all":
        FIREFOX_VERSION = matrix["CDP"][cdp_version]["FIREFOX_VERSION"]
        f.write(f"FIREFOX_VERSION={FIREFOX_VERSION}\n")
      if browser_name == "edge" or browser_name == "all":
        EDGE_VERSION = matrix["CDP"][cdp_version]["EDGE_VERSION"]
        f.write(f"EDGE_VERSION={EDGE_VERSION}\n")
      if browser_name == "chrome" or browser_name == "all":
        CHROME_VERSION = matrix["CDP"][cdp_version]["CHROME_VERSION"]
        f.write(f"CHROME_VERSION={CHROME_VERSION}")
