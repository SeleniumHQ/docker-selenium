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
        resources_name = ['{0}selenium-chrome-node'.format(RELEASE_NAME),
                          '{0}selenium-distributor'.format(RELEASE_NAME),
                          '{0}selenium-edge-node'.format(RELEASE_NAME),
                          '{0}selenium-firefox-node'.format(RELEASE_NAME),
                          '{0}selenium-event-bus'.format(RELEASE_NAME),
                          '{0}selenium-router'.format(RELEASE_NAME),
                          '{0}selenium-session-map'.format(RELEASE_NAME),
                          '{0}selenium-session-queue'.format(RELEASE_NAME)]
        count = 0
        logger.info(f"Assert affinity is set in global and nodes")
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert affinity is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['template']['spec']['affinity']['podAffinity']['requiredDuringSchedulingIgnoredDuringExecution'][0]['labelSelector']['matchExpressions'] is not None)
                count += 1
        self.assertEqual(count, len(resources_name), "Not all resources have affinity set")

    def test_ingress_nginx_annotations(self):
        resources_name = ['{0}selenium-ingress'.format(RELEASE_NAME)]
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
        resources_name = ['{0}selenium-node-config'.format(RELEASE_NAME)]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert subPath is appended to Node env SE_NODE_GRID_URL")
                self.assertTrue(doc['data']['SE_NODE_GRID_URL'] == 'https://sysadmin:strongPassword@10.10.10.10:8443/selenium')
                count += 1
        self.assertEqual(count, len(resources_name), "No node config resources found")

    def test_sub_path_set_to_grid_env_var(self):
        resources_name = ['{0}selenium-router'.format(RELEASE_NAME)]
        is_present = False
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert subPath is set to Router env SE_SUB_PATH")
                list_env = doc['spec']['template']['spec']['containers'][0]['env']
                for env in list_env:
                    if env['name'] == 'SE_SUB_PATH' and env['value'] == '/selenium':
                        is_present = True
        self.assertTrue(is_present, "ENV variable SE_SUB_PATH is not populated")

    def test_graphql_url_for_autoscaling_constructed_correctly(self):
        resources_name = ['{0}selenium-chrome-node'.format(RELEASE_NAME),]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ScaledObject':
                logger.info(f"Assert trigger url is set GraphQL endpoint in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['triggers'][0]['metadata']['url'] == 'https://sysadmin:strongPassword@{0}selenium-router.default:4444/selenium/graphql'.format(RELEASE_NAME))
                count += 1
        self.assertEqual(count, len(resources_name), "GraphQL endpoint is not set correctly")

    def test_distributor_new_session_thread_pool_size(self):
        resources_name = ['{0}selenium-distributor'.format(RELEASE_NAME)]
        is_present = False
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert newSessionThreadPoolSize is set to Distributor env SE_NEW_SESSION_THREAD_POOL_SIZE")
                list_env = doc['spec']['template']['spec']['containers'][0]['env']
                for env in list_env:
                    if env['name'] == 'SE_NEW_SESSION_THREAD_POOL_SIZE' and env['value'] == '24':
                        is_present = True
        self.assertTrue(is_present, "ENV variable SE_NEW_SESSION_THREAD_POOL_SIZE is not populated")

    def test_disable_ui_set_to_grid_env_var(self):
        resources_name = ['{0}selenium-router'.format(RELEASE_NAME)]
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
        resources_name = ['{0}selenium-chrome-node'.format(RELEASE_NAME),
                          '{0}selenium-distributor'.format(RELEASE_NAME),
                          '{0}selenium-edge-node'.format(RELEASE_NAME),
                          '{0}selenium-firefox-node'.format(RELEASE_NAME),
                          '{0}selenium-event-bus'.format(RELEASE_NAME),
                          '{0}selenium-router'.format(RELEASE_NAME),
                          '{0}selenium-session-map'.format(RELEASE_NAME),
                          '{0}selenium-session-queue'.format(RELEASE_NAME)]
        logger.info(f"Assert log level value is set to logging ConfigMap")
        count_config = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] == '{0}selenium-logging-config'.format(RELEASE_NAME) and doc['kind'] == 'ConfigMap':
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
                        if env['configMapRef']['name'] == '{0}selenium-logging-config'.format(RELEASE_NAME):
                            is_present = True
                self.assertTrue(is_present, "envFrom doesn't contain logging ConfigMap")
                count += 1
        self.assertEqual(count, len(resources_name), "Logging ConfigMap is not present in expected resources")

    def test_node_port_set_when_service_type_is_node_port(self):
        single_node_port = {'{0}selenium-distributor'.format(RELEASE_NAME): 30553,
                            '{0}selenium-router'.format(RELEASE_NAME): 30444,
                            '{0}selenium-session-queue'.format(RELEASE_NAME): 30559}
        count = 0
        logger.info(f"Assert NodePort is set to components service")
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in single_node_port.keys() and doc['kind'] == 'Service':
                logger.info(f"Assert NodePort is set to service {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['ports'][0]['nodePort'] == single_node_port[doc['metadata']['name']], f"Service {doc['metadata']['name']} with expect NodePort {single_node_port[doc['metadata']['name']]} is not found")
                count += 1
        self.assertEqual(count, len(single_node_port.keys()), "Number of services with NodePort is not correct")

    def test_all_metadata_name_is_prefixed_with_release_name(self):
        logger.info(f"Assert all metadata name is prefixed with RELEASE NAME")
        prefix = "selenium-" if RELEASE_NAME == "" else RELEASE_NAME
        for doc in LIST_OF_DOCUMENTS:
            logger.info(f"Assert metadata name: {doc['metadata']['name']}")
            self.assertTrue(doc['metadata']['name'].startswith(RELEASE_NAME),
                            f"Metadata name {doc['metadata']['name']} is not prefixed with RELEASE NAME: {RELEASE_NAME}")

    def test_extra_script_import_to_node_configmap(self):
        resources_name = ['{0}selenium-node-config'.format(RELEASE_NAME)]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert default file is imported to Node ConfigMap")
                self.assertTrue(doc['data']['nodeProbe.sh'] != "")
                self.assertTrue(doc['data']['nodePreStop.sh'] != "")
                self.assertTrue(doc['data']['nodeCustomTask.sh'] != "")
                self.assertTrue(doc['data']['setFromCommand.sh'] != "")
                count += 1
        self.assertEqual(count, len(resources_name), "No node config resources found")

    def test_extra_script_import_to_uploader_configmap(self):
        resources_name = ['{0}selenium-uploader-config'.format(RELEASE_NAME)]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert extra script is imported to Uploader ConfigMap")
                self.assertTrue(doc['data']['upload.sh'] is not None)
                self.assertTrue(doc['data']['setFromCommand.sh'] is not None)
                count += 1
        self.assertEqual(count, len(resources_name), "No uploader config resources found")

    def test_extra_script_import_to_recorder_configmap(self):
        resources_name = ['{0}selenium-recorder-config'.format(RELEASE_NAME)]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert extra script is imported to Recorder ConfigMap")
                self.assertTrue(doc['data']['video.sh'] is not None)
                self.assertTrue(doc['data']['setFromCommand.sh'] is not None)
                count += 1
        self.assertEqual(count, len(resources_name), "No recorder config resources found")

    def test_upload_conf_mount_to_video_container(self):
        resources_name = ['{0}selenium-chrome-node'.format(RELEASE_NAME),
                          '{0}selenium-edge-node'.format(RELEASE_NAME),
                          '{0}selenium-firefox-node'.format(RELEASE_NAME),]
        is_present = False
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert upload config is mounted to the container")
                video_container = None
                uploader_container = None
                for container in doc['spec']['template']['spec']['containers']:
                    if container['name'] == 'video':
                        video_container = container
                    if container['name'] == 's3':
                        uploader_container = container
                list_volume_mounts = None
                if uploader_container is not None:
                    list_volume_mounts = uploader_container['volumeMounts']
                else:
                    list_volume_mounts = video_container['volumeMounts']
                for volume in list_volume_mounts:
                    if volume['mountPath'] == '/opt/bin/upload.conf':
                        is_present = True
        self.assertTrue(is_present, "Volume mount for upload config is not present in the container")

    def test_terminationGracePeriodSeconds_in_deployment_autoscaling(self):
        resources_name = ['{0}selenium-chrome-node'.format(RELEASE_NAME),]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert terminationGracePeriodSeconds is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['template']['spec']['terminationGracePeriodSeconds'] == 7200)
                count += 1
        self.assertEqual(count, len(resources_name), "node.terminationGracePeriodSeconds doesn't override a higher value than autoscaling.terminationGracePeriodSeconds")

        resources_name = ['{0}selenium-edge-node'.format(RELEASE_NAME),
                          '{0}selenium-firefox-node'.format(RELEASE_NAME),]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert terminationGracePeriodSeconds is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['template']['spec']['terminationGracePeriodSeconds'] == 3600)
                count += 1
        self.assertEqual(count, len(resources_name), "node.terminationGracePeriodSeconds doesn't inherit the global value autoscaling.terminationGracePeriodSeconds")

    def test_enable_leftovers_cleanup(self):
        resources_name = ['{0}selenium-node-config'.format(RELEASE_NAME)]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert ENV vars for function leftovers cleanup is set to Node ConfigMap")
                self.assertEqual(doc['data']['SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP'], 'true')
                self.assertEqual(doc['data']['SE_BROWSER_LEFTOVERS_INTERVAL_SECS'], '3600')
                self.assertEqual(doc['data']['SE_BROWSER_LEFTOVERS_PROCESSES_SECS'], '7200')
                self.assertEqual(doc['data']['SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS'], '1')
                count += 1
        self.assertEqual(count, len(resources_name), "No node config resources found")

    def test_enable_tracing(self):
        resources_name = ['{0}selenium-logging-config'.format(RELEASE_NAME)]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'ConfigMap':
                logger.info(f"Assert ENV vars for Tracing disabled is set to Node ConfigMap")
                self.assertEqual(doc['data']['SE_ENABLE_TRACING'], 'false')
                count += 1
        self.assertEqual(count, len(resources_name), "No node config resources found")

    def test_update_strategy_in_all_components(self):
        recreate = ['{0}selenium-distributor'.format(RELEASE_NAME),
                    '{0}selenium-event-bus'.format(RELEASE_NAME),
                    '{0}selenium-router'.format(RELEASE_NAME),
                    '{0}selenium-session-map'.format(RELEASE_NAME),
                    '{0}selenium-session-queue'.format(RELEASE_NAME),]
        rolling  = ['{0}selenium-chrome-node'.format(RELEASE_NAME),
                    '{0}selenium-edge-node'.format(RELEASE_NAME),
                    '{0}selenium-firefox-node'.format(RELEASE_NAME),]
        count_recreate = 0
        count_rolling = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in rolling and doc['kind'] == 'Deployment':
                logger.info(f"Assert updateStrategy is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['strategy']['type'] == 'RollingUpdate', f"Resource {doc['metadata']['name']} doesn't have strategy RollingUpdate")
                count_rolling += 1
            if doc['metadata']['name'] in recreate and doc['kind'] == 'Deployment':
                logger.info(f"Assert updateStrategy is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['strategy']['type'] == 'Recreate', f"Resource {doc['metadata']['name']} doesn't have strategy Recreate")
                count_recreate += 1
        self.assertEqual(count_rolling, len(rolling), "No deployment resources found with strategy RollingUpdate")
        self.assertEqual(count_recreate, len(recreate), "No deployment resources found with strategy Recreate")

    def test_topologySpreadConstraints_in_all_components(self):
        resources_name = ['{0}selenium-chrome-node'.format(RELEASE_NAME),
                          '{0}selenium-edge-node'.format(RELEASE_NAME),
                          '{0}selenium-firefox-node'.format(RELEASE_NAME),
                          '{0}selenium-distributor'.format(RELEASE_NAME),
                          '{0}selenium-event-bus'.format(RELEASE_NAME),
                          '{0}selenium-router'.format(RELEASE_NAME),
                          '{0}selenium-session-map'.format(RELEASE_NAME),
                          '{0}selenium-session-queue'.format(RELEASE_NAME),]
        count = 0
        for doc in LIST_OF_DOCUMENTS:
            if doc['metadata']['name'] in resources_name and doc['kind'] == 'Deployment':
                logger.info(f"Assert topologySpreadConstraints is set in resource {doc['metadata']['name']}")
                self.assertTrue(doc['spec']['template']['spec']['topologySpreadConstraints'][0]['labelSelector']['matchLabels']['app'] == doc['metadata']['name'])
                count += 1
        self.assertEqual(count, len(resources_name), "No deployment resources found with topologySpreadConstraints")

if __name__ == '__main__':
    failed = False
    try:
        FILE_NAME = sys.argv[1]
        RELEASE_NAME = sys.argv[2]
        if RELEASE_NAME == "selenium":
            RELEASE_NAME = ""
        else:
            RELEASE_NAME = RELEASE_NAME + "-"
        LIST_OF_DOCUMENTS = load_template(FILE_NAME)
        suite = unittest.TestLoader().loadTestsFromTestCase(ChartTemplateTests)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    if failed:
        exit(1)
