import logging
import sys
import unittest

import yaml

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


def load_template(yaml_file):
    try:
        with open(yaml_file) as file:
            documents = yaml.safe_load_all(file)
            return [doc for doc in documents if doc]
    except yaml.YAMLError as error:
        print("Error in configuration file: ", error)


def find_docs(kind, name=None):
    return [
        doc
        for doc in LIST_OF_DOCUMENTS
        if doc.get("kind") == kind and (name is None or doc.get("metadata", {}).get("name") == name)
    ]


def find_doc(kind, name):
    matches = find_docs(kind, name)
    if not matches:
        raise AssertionError(f"Expected {kind} {name} to be present")
    return matches[0]


def get_container(deployment):
    return deployment["spec"]["template"]["spec"]["containers"][0]


def get_env_map(container):
    return {env["name"]: env.get("value") for env in container.get("env", [])}


def get_env_from_refs(container):
    refs = []
    for env_from in container.get("envFrom", []):
        if env_from.get("configMapRef"):
            refs.append(("configMapRef", env_from["configMapRef"]["name"]))
        if env_from.get("secretRef"):
            refs.append(("secretRef", env_from["secretRef"]["name"]))
    return refs


def get_volume_mount(container, name):
    for volume_mount in container.get("volumeMounts", []):
        if volume_mount["name"] == name:
            return volume_mount
    raise AssertionError(f"Expected volumeMount {name} to be present")


def get_volume(deployment, name):
    for volume in deployment["spec"]["template"]["spec"].get("volumes", []):
        if volume["name"] == name:
            return volume
    raise AssertionError(f"Expected volume {name} to be present")


class DynamicGridTemplateTests(unittest.TestCase):
    def test_dynamic_grid_does_not_render_keda_resources(self):
        logger.info("Assert Dynamic Grid render does not include KEDA resources")
        keda_resources = [doc for doc in LIST_OF_DOCUMENTS if doc.get("kind") in ["ScaledJob", "ScaledObject"]]
        self.assertEqual(keda_resources, [])

    def test_dynamic_grid_supporting_resources(self):
        logger.info("Assert Dynamic Grid service account, RBAC, PVC, and template ConfigMap are rendered")
        service_account = find_doc("ServiceAccount", f"{RELEASE_NAME}-dynamic-grid")
        self.assertEqual(service_account["metadata"]["name"], f"{RELEASE_NAME}-dynamic-grid")

        role = find_doc("Role", f"{RELEASE_NAME}-dynamic-grid-role")
        resources = [resource for rule in role["rules"] for resource in rule["resources"]]
        self.assertIn("jobs", resources)
        self.assertIn("pods", resources)

        role_binding = find_doc("RoleBinding", f"{RELEASE_NAME}-dynamic-grid-rolebinding")
        self.assertEqual(role_binding["subjects"][0]["name"], f"{RELEASE_NAME}-dynamic-grid")
        self.assertEqual(role_binding["roleRef"]["name"], f"{RELEASE_NAME}-dynamic-grid-role")

        pvc = find_doc("PersistentVolumeClaim", f"{RELEASE_NAME}-dynamic-assets")
        self.assertEqual(pvc["spec"]["accessModes"], ["ReadWriteMany"])
        self.assertEqual(pvc["spec"]["resources"]["requests"]["storage"], "5Gi")

        job_template = find_doc("ConfigMap", f"{RELEASE_NAME}-dynamic-job-template-chrome-dev-template")
        self.assertIn("image: selenium/standalone-chrome:dev", job_template["data"]["template"])

    def test_dynamic_grid_structured_toml_node(self):
        logger.info("Assert structured Dynamic Grid pool renders ConfigMap and Deployment correctly")
        configmap = find_doc("ConfigMap", f"{RELEASE_NAME}-dynamic-node-linux-stable-config")
        toml = configmap["data"]["kubernetes.toml"]
        self.assertIn("selenium/standalone-chromium:4.42.0-20260303", toml)
        self.assertIn(
            f'configmap:{RELEASE_NAME}-dynamic-job-template-chrome-dev-template',
            toml,
        )
        self.assertIn('"browserVersion":"dev"', toml)

        deployment = find_doc("Deployment", f"{RELEASE_NAME}-dynamic-node-linux-stable")
        self.assertEqual(deployment["spec"]["template"]["spec"]["serviceAccountName"], f"{RELEASE_NAME}-dynamic-grid")
        self.assertEqual(deployment["metadata"]["labels"]["tier"], "dynamic")

        container = get_container(deployment)
        self.assertEqual(container["image"], "selenium/node-kubernetes:4.42.0-20260303")
        env_map = get_env_map(container)
        self.assertEqual(env_map["SE_NODE_KUBERNETES_CONFIG_FILENAME"], "kubernetes.toml")
        self.assertEqual(env_map["SE_DYNAMIC_MAX_SESSIONS"], "10")
        self.assertEqual(env_map["SE_DYNAMIC_OVERRIDE_MAX_SESSIONS"], "true")
        self.assertEqual(env_map["SE_NODE_SESSION_TIMEOUT"], "600")

        env_from_refs = get_env_from_refs(container)
        self.assertIn(("configMapRef", f"{RELEASE_NAME}-event-bus-config"), env_from_refs)
        self.assertIn(("configMapRef", f"{RELEASE_NAME}-logging-config"), env_from_refs)
        self.assertIn(("configMapRef", f"{RELEASE_NAME}-server-config"), env_from_refs)
        self.assertIn(("secretRef", f"{RELEASE_NAME}-secrets"), env_from_refs)

        config_mount = get_volume_mount(container, "dynamic-grid-config")
        self.assertEqual(config_mount["mountPath"], "/opt/selenium/kubernetes.toml")
        self.assertEqual(config_mount["subPath"], "kubernetes.toml")

        assets_mount = get_volume_mount(container, "dynamic-grid-assets")
        self.assertEqual(assets_mount["mountPath"], "/opt/selenium/assets")

        config_volume = get_volume(deployment, "dynamic-grid-config")
        self.assertEqual(config_volume["configMap"]["name"], f"{RELEASE_NAME}-dynamic-node-linux-stable-config")
        assets_volume = get_volume(deployment, "dynamic-grid-assets")
        self.assertEqual(assets_volume["persistentVolumeClaim"]["claimName"], f"{RELEASE_NAME}-dynamic-assets")

    def test_dynamic_grid_raw_toml_node_and_service(self):
        logger.info("Assert raw TOML node supports custom filename and optional Service")
        configmap = find_doc("ConfigMap", f"{RELEASE_NAME}-dynamic-node-firefox-beta-config")
        toml = configmap["data"]["firefox-beta.toml"]
        self.assertIn('"browserVersion":"beta"', toml)
        self.assertIn('termination-grace-period = 90', toml)

        deployment = find_doc("Deployment", f"{RELEASE_NAME}-dynamic-node-firefox-beta")
        container = get_container(deployment)
        env_map = get_env_map(container)
        self.assertEqual(env_map["SE_NODE_KUBERNETES_CONFIG_FILENAME"], "firefox-beta.toml")

        config_mount = get_volume_mount(container, "dynamic-grid-config")
        self.assertEqual(config_mount["mountPath"], "/opt/selenium/firefox-beta.toml")
        self.assertEqual(config_mount["subPath"], "firefox-beta.toml")

        service = find_doc("Service", f"{RELEASE_NAME}-dynamic-node-firefox-beta")
        self.assertEqual(service["spec"]["ports"][0]["port"], 5555)
        self.assertEqual(service["spec"]["selector"]["app"], f"{RELEASE_NAME}-dynamic-node-firefox-beta")


if __name__ == "__main__":
    failed = False
    try:
        FILE_NAME = sys.argv[1]
        RELEASE_NAME = sys.argv[2]
        LIST_OF_DOCUMENTS = load_template(FILE_NAME)
        suite = unittest.TestLoader().loadTestsFromTestCase(DynamicGridTemplateTests)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    if failed:
        exit(1)
