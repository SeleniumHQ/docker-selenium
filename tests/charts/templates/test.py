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
        resources_name = ['{0}-selenium-chrome-node'.format(RELEASE_NAME),
                          '{0}-selenium-distributor'.format(RELEASE_NAME),
                          '{0}-selenium-edge-node'.format(RELEASE_NAME),
                          '{0}-selenium-firefox-node'.format(RELEASE_NAME),
                          '{0}-selenium-event-bus'.format(RELEASE_NAME),
                          '{0}-selenium-router'.format(RELEASE_NAME),
                          '{0}-selenium-session-map'.format(RELEASE_NAME),
                          '{0}-selenium-session-queue'.format(RELEASE_NAME)]
        count = 0
        logger.info(f"Assert affinity is set in global and nodes")
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert affinity is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['template']['spec']['affinity']['podAffinity']['requiredDuringSchedulingIgnoredDuringExecution'][0]['labelSelector']['matchExpressions'] is not None)
                count += 1
        self.assertEqual(count, len(resources_name), "Not all resources have affinity set")

    def test_ingress_nginx_annotations(self):
        resources_name = ['{0}-selenium-ingress'.format(RELEASE_NAME)]
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
        resources_name = ['{0}-selenium-node-config'.format(RELEASE_NAME)]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert subPath is appended to Node env SE_NODE_GRID_URL")
                self.assertTrue(doc['data']['SE_NODE_GRID_URL'] == 'https://sysadmin:strongPassword@10.10.10.10:8443/selenium')
                count += 1
        self.assertEqual(count, len(resources_name), "No node config resources found")

    def test_sub_path_set_to_grid_env_var(self):
        resources_name = ['{0}-selenium-router'.format(RELEASE_NAME)]
        is_present = False
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert subPath is set to Router env SE_SUB_PATH")
                list_env = doc['spec']['template']['spec']['containers'][0]['env']
                for env in list_env:
                    if env['name'] == 'SE_SUB_PATH' and env['value'] == '/selenium':
                        is_present = True
        self.assertTrue(is_present, "ENV variable SE_SUB_PATH is not populated")

    def test_disable_ui_set_to_grid_env_var(self):
        resources_name = ['{0}-selenium-router'.format(RELEASE_NAME)]
        is_present = False
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert option disable UI is set to Router env SE_DISABLE_UI")
                list_env = doc['spec']['template']['spec']['containers'][0]['env']
                for env in list_env:
                    if env['name'] == 'SE_DISABLE_UI' and env['value'] == 'true':
                        is_present = True
        self.assertTrue(is_present, "ENV variable SE_DISABLE_UI is not populated")

    def test_log_level_set_to_logging_config_map(self):
        resources_name = ['{0}-selenium-chrome-node'.format(RELEASE_NAME),
                          '{0}-selenium-distributor'.format(RELEASE_NAME),
                          '{0}-selenium-edge-node'.format(RELEASE_NAME),
                          '{0}-selenium-firefox-node'.format(RELEASE_NAME),
                          '{0}-selenium-event-bus'.format(RELEASE_NAME),
                          '{0}-selenium-router'.format(RELEASE_NAME),
                          '{0}-selenium-session-map'.format(RELEASE_NAME),
                          '{0}-selenium-session-queue'.format(RELEASE_NAME)]
        logger.info(f"Assert log level value is set to logging ConfigMap")
        count_config = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] == '{0}-selenium-logging-config'.format(RELEASE_NAME) and doc['kind'] == 'ConfigMap':
                self.assertTrue(doc['data']['SE_LOG_LEVEL'] == 'FINE')
                count_config += 1
        self.assertEqual(count_config, 1, "No logging ConfigMap found")
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                is_present = False
                logger.info(f"Assert logging ConfigMap is set to envFrom in resource {doc['metadata']['name']}")
                list_env_from = doc['spec']['template']['spec']['containers'][0]['envFrom']
                for env in list_env_from:
                    if env.get('configMapRef') is not None:
                        if env['configMapRef']['name'] == '{0}-selenium-logging-config'.format(RELEASE_NAME):
                            is_present = True
                self.assertTrue(is_present, "envFrom doesn't contain logging ConfigMap")
                count += 1
        self.assertEqual(count, len(resources_name), "Logging ConfigMap is not present in expected resources")

    def test_node_port_set_when_service_type_is_node_port(self):
        single_node_port = {'{0}-selenium-distributor'.format(RELEASE_NAME): 30553,
                            '{0}-selenium-router'.format(RELEASE_NAME): 30444,
                            '{0}-selenium-session-queue'.format(RELEASE_NAME): 30559}
        count = 0
        logger.info(f"Assert NodePort is set to components service")
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in single_node_port.keys() and doc['kind'] == 'Service':
                logger.info(f"Assert NodePort is set to service {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['ports'][0]['nodePort'] == single_node_port[doc['metadata']['name']], f"Service {doc['metadata']['name']} with expect NodePort {single_node_port[doc['metadata']['name']]} is not found")
                count += 1
        self.assertEqual(count, len(single_node_port.keys()), "Number of services with NodePort is not correct")

if __name__ == '__main__':
    failed = False
    try:
        FILE_NAME = sys.argv[1]
        RELEASE_NAME = sys.argv[2]
        LIST_OF_DOCUMENTS = load_template(FILE_NAME)
        suite = unittest.TestLoader().loadTestsFromTestCase(ChartTemplateTests)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    if failed:
        exit(1)
