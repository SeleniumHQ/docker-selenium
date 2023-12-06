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
        resources_name = ['selenium-chrome-node', 'selenium-distributor', 'selenium-edge-node', 'selenium-firefox-node',
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
