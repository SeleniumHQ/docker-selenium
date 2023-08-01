import logging
import os
import random
import sys
import unittest
import re

import docker
from docker.errors import NotFound

# LOGGING #
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

NAMESPACE = os.environ.get('NAMESPACE')
VERSION = os.environ.get('VERSION')
USE_RANDOM_USER_ID = os.environ.get('USE_RANDOM_USER_ID')
RUN_IN_DOCKER_COMPOSE = os.environ.get('RUN_IN_DOCKER_COMPOSE')
http_proxy = os.environ.get('http_proxy', '')
https_proxy = os.environ.get('https_proxy', '')
no_proxy = os.environ.get('no_proxy', '')
SKIP_BUILD = os.environ.get('SKIP_BUILD', False)

try:
    client = docker.from_env()
except:
    client = None

IMAGE_NAME_MAP = {
    # Hub
    'Hub': 'hub',

    # Chrome Images
    'NodeChrome': 'node-chrome',
    'StandaloneChrome': 'standalone-chrome',

    # Edge Images
    'NodeEdge': 'node-edge',
    'StandaloneEdge': 'standalone-edge',

    # Firefox Images
    'NodeFirefox': 'node-firefox',
    'StandaloneFirefox': 'standalone-firefox',
}

TEST_NAME_MAP = {
    # Chrome Images
    'NodeChrome': 'ChromeTests',
    'StandaloneChrome': 'ChromeTests',

    # Edge Images
    'NodeEdge': 'EdgeTests',
    'StandaloneEdge': 'EdgeTests',

    # Firefox Images
    'NodeFirefox': 'FirefoxTests',
    'StandaloneFirefox': 'FirefoxTests',
}

FROM_IMAGE_ARGS = {
    'NAMESPACE': NAMESPACE,
    'VERSION': VERSION
}

def launch_hub(network_name):
    """
    Launch the hub
    :return: the hub ID
    """
    logger.info("Launching Hub...")

    existing_hub = None

    try:
        existing_hub = client.containers.get('selenium-hub')
    except NotFound:
        pass

    if existing_hub:
        logger.debug("hub already exists. removing.")
        if existing_hub.status == 'running':
            logger.debug("hub is running. Killing")
            existing_hub.kill()
            logger.debug("hub killed")
        existing_hub.remove()
        logger.debug("hub removed")

    grid_ports = {'4442': 4442, '4443': 4443, '4444': 4444}
    if use_random_user_id:
        hub_container_id = launch_container('Hub', network=network_name, name="selenium-hub",
                                            ports=grid_ports, user=random_user_id)
    else:
        hub_container_id = launch_container('Hub', network=network_name, name="selenium-hub",
                                            ports=grid_ports)

    logger.info("Hub Launched")
    return hub_container_id


def create_network(network_name):
    client.networks.create(network_name, driver="bridge")


def prune_networks():
    client.networks.prune()


def launch_container(container, **kwargs):
    """
    Launch a specific container
    :param container:
    :return: the container ID
    """
    skip_building_images = SKIP_BUILD == 'true'
    if skip_building_images:
        logger.info("SKIP_BUILD is true...not rebuilding images...")
    else:
        # Build the container if it doesn't exist
        logger.info("Building %s container..." % container)
        set_from_image_base_for_standalone(container)
        build_path = get_build_path(container)
        client.images.build(path='../%s' % build_path,
                            tag="%s/%s:%s" % (NAMESPACE, IMAGE_NAME_MAP[container], VERSION),
                            rm=True,
                            buildargs=FROM_IMAGE_ARGS)
        logger.info("Done building %s" % container)

    # Run the container
    logger.info("Running %s container..." % container)
    # Merging env vars
    environment = {
        'http_proxy': http_proxy,
        'https_proxy': https_proxy,
        'no_proxy': no_proxy,
        'SE_EVENT_BUS_HOST': 'selenium-hub',
        'SE_EVENT_BUS_PUBLISH_PORT': 4442,
        'SE_EVENT_BUS_SUBSCRIBE_PORT': 4443
    }
    container_id = client.containers.run("%s/%s:%s" % (NAMESPACE, IMAGE_NAME_MAP[container], VERSION),
                                         detach=True,
                                         environment=environment,
                                         shm_size="2G",
                                         **kwargs).short_id
    logger.info("%s up and running" % container)
    return container_id


def set_from_image_base_for_standalone(container):
    match = standalone_browser_container_matches(container)
    if match != None:
      FROM_IMAGE_ARGS['BASE'] = 'node-' + match.group(2).lower()


def get_build_path(container):
    match = standalone_browser_container_matches(container)
    if match == None:
      return container
    else:
      return match.group(1)


def standalone_browser_container_matches(container):
    return re.match("(Standalone)(Chrome|Firefox|Edge)", container)


if __name__ == '__main__':
    # The container to test against
    image = sys.argv[1]

    use_random_user_id = USE_RANDOM_USER_ID == 'true'
    run_in_docker_compose = RUN_IN_DOCKER_COMPOSE == 'true'
    random_user_id = random.randint(100000, 2147483647)

    if use_random_user_id:
        logger.info("Running tests with a random user ID -> %s" % random_user_id)

    standalone = 'standalone' in image.lower()

    # Flag for failure (for posterity)
    failed = False

    # Avoiding to start the containers when running inside docker-compose
    test_container_id = ''
    hub_id = ''
    if not run_in_docker_compose:
        logger.info('========== Starting %s Container ==========' % image)

        if standalone:
            """
            Standalone Configuration
            """
            ports = {'4444': 4444}
            if use_random_user_id:
                test_container_id = launch_container(image, ports=ports, user=random_user_id)
            else:
                test_container_id = launch_container(image, ports=ports)
        else:
            """
            Hub / Node Configuration
            """
            prune_networks()
            create_network("grid")
            hub_id = launch_hub("grid")
            ports = {'5555': 5555, '7900': 7900}
            if use_random_user_id:
                test_container_id = launch_container(image, network='grid', ports=ports, user=random_user_id)
            else:
                test_container_id = launch_container(image, network='grid', ports=ports)
            prune_networks()

        logger.info('========== / Containers ready to go ==========')

    try:
        # Smoke tests
        logger.info('*********** Running smoke tests %s Tests **********' % image)
        image_class = "%sTest" % image
        module = __import__('SmokeTests', fromlist='GridTest')
        test_class = getattr(module, 'GridTest')
        suite = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    try:
        # Run Selenium tests
        logger.info('*********** Running Selenium tests %s Tests **********' % image)
        test_class = getattr(__import__('SeleniumTests', fromlist=[TEST_NAME_MAP[image]]), TEST_NAME_MAP[image])
        suite = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    # Avoiding a container cleanup if tests run inside docker-compose
    if not run_in_docker_compose:
        logger.info("Cleaning up...")

        test_container = client.containers.get(test_container_id)
        test_container.kill()
        test_container.remove()

        if standalone:
            logger.info("Standalone Cleaned up")
        else:
            # Kill the launched hub
            hub = client.containers.get(hub_id)
            hub.kill()
            hub.remove()
            logger.info("Hub / Node Cleaned up")

    if failed:
        exit(1)
