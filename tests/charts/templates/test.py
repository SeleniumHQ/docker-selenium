import yaml
import unittest
import sys
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

def load_template(yaml_file):
    try:
        with open(yaml_file, 'r') as file:
            documents = yaml.safe_load_all(file)
            list_of_documents = [doc for doc in documents]
            return list_of_documents
    except yaml.YAMLError as error:
        print("Error in configuration file: ", error)

class ChartTemplateTests(unittest.TestCase):
    def test_set_affinity(self):
        resources_name = ['selenium-chrome-node', 'selenium-distributor', 'selenium-edge-node', 'selenium-firefox-node', 'selenium-chromium-node',
                'selenium-event-bus', 'selenium-router', 'selenium-session-map', 'selenium-session-queue']
        count = 0
        logger.info(f"Assert affinity is set in global and nodes")
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert affinity is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['template']['spec']['affinity']['podAffinity']['requiredDuringSchedulingIgnoredDuringExecution'][0]['labelSelector']['matchExpressions'] is not None)
                count += 1
        self.assertEqual(count, len(resources_name), "Not all resources have affinity set")

    def test_ingress_nginx_annotations(self):
        resources_name = ['selenium-ingress']
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Ingress':
                logger.info(f"Assert ingress ingress annotations")
                logger.info(f"Config `ingress.nginx.proxyTimeout` is able to be set a different value")
                self.assertTrue(doc['metadata']['annotations']['nginx.ingress.kubernetes.io/proxy-read-timeout'] == '360')
                logger.info(f"Duplicated in `ingress.annotations` take precedence to overwrite the default value")
                self.assertTrue(doc['metadata']['annotations']['nginx.ingress.kubernetes.io/proxy-connect-timeout'] == '3600')
                logger.info(f"Default annotation is able to be disabled by setting it to null")
                self.assertTrue(doc['metadata']['annotations'].get('nginx.ingress.kubernetes.io/proxy-buffers-number')  is None)
                logger.info(f"Default annotation is added if no override value")
                self.assertTrue(doc['metadata']['annotations']['nginx.ingress.kubernetes.io/client-body-buffer-size']  == '512M')
                count += 1
        self.assertEqual(count, len(resources_name), "No ingress resources found")

    def test_sub_path_append_to_node_grid_url(self):
        resources_name = ['selenium-node-config']
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert subPath is appended to node grid url")
                self.assertTrue(doc['data']['SE_NODE_GRID_URL'] == 'http://admin:admin@selenium-router.default:4444/selenium')
                count += 1
        self.assertEqual(count, len(resources_name), "No node config resources found")

    def test_sub_path_set_to_grid_env_var(self):
        resources_name = ['selenium-router']
        is_present = False
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert subPath is set to grid ENV variable")
                list_env = doc['spec']['template']['spec']['containers'][0]['env']
                for env in list_env:
                    if env['name'] == 'SE_SUB_PATH' and env['value'] == '/selenium':
                        is_present = True
        self.assertTrue(is_present, "ENV variable SE_SUB_PATH is not populated")

if __name__ == '__main__':
    failed = False
    try:
        FILE_NAME = sys.argv[1]
        LIST_OF_DOCUMENTS = load_template(FILE_NAME)
        suite = unittest.TestLoader().loadTestsFromTestCase(ChartTemplateTests)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    if failed:
        exit(1)
