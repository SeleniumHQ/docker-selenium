import os
import docker
import unittest
import logging
import sys

from docker.errors import NotFound

# LOGGING #
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Docker Client
client = docker.from_env()

NAMESPACE = os.environ.get('NAMESPACE')
VERSION = os.environ.get('VERSION')

IMAGE_NAME_MAP = {
    # Hub
    'Hub': 'hub',

    # Chrome Images
    'NodeChrome': 'node-chrome',
    'NodeChromeDebug': 'node-chrome-debug',
    'StandaloneChrome': 'standalone-chrome',
    'StandaloneChromeDebug': 'standalone-chrome-debug',

    # Firefox Images
    'NodeFirefox': 'node-firefox',
    'NodeFirefoxDebug': 'node-firefox-debug',
    'StandaloneFirefox': 'standalone-firefox',
    'StandaloneFirefoxDebug': 'standalone-firefox-debug',
}

TEST_NAME_MAP = {
    # Chrome Images
    'NodeChrome': 'ChromeTests',
    'NodeChromeDebug': 'ChromeTests',
    'StandaloneChrome': 'ChromeTests',
    'StandaloneChromeDebug': 'ChromeTests',

    # Firefox Images
    'NodeFirefox': 'FirefoxTests',
    'NodeFirefoxDebug': 'FirefoxTests',
    'StandaloneFirefox': 'FirefoxTests',
    'StandaloneFirefoxDebug': 'FirefoxTests',
}


def launch_hub():
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
    hub_container_id = launch_container('Hub', ports={'4444': 4444})
    logger.info("Hub Launched")
    return hub_container_id


def launch_container(container, **kwargs):
    """
    Launch a specific container
    :param container:
    :return: the container ID
    """
    # Build the container if it doesn't exist
    logger.info("Building %s container..." % container)
    client.images.build(path='../%s' % container,
                        tag="%s/%s:%s" % (NAMESPACE, IMAGE_NAME_MAP[container], VERSION),
                        rm=True)
    logger.info("Done building %s" % container)

    # Run the container
    logger.info("Running %s container..." % container)
    container_id = client.containers.run("%s/%s:%s" % (NAMESPACE, IMAGE_NAME_MAP[container], VERSION),
                                         detach=True,
                                         **kwargs).short_id
    logger.info("%s up and running" % container)
    return container_id


if __name__ == '__main__':
    # The container to test against
    image = sys.argv[1]

    standalone = 'standalone' in image.lower()

    # Flag for failure (for posterity)
    failed = False

    logger.info('========== Starting %s Container ==========' % image)

    if standalone:
        """
        Standalone Configuration
        """
        smoke_test_class = 'StandaloneTest'
        test_container_id = launch_container(image, ports={'4444': 4444})
    else:
        """
        Hub / Node Configuration
        """
        smoke_test_class = 'NodeTest'
        hub_id = launch_hub()
        test_container_id = launch_container(image, links={hub_id: 'hub'}, ports={'5555': 5555})

    logger.info('========== / Containers ready to go ==========')

    try:
        # Smoke tests
        logger.info('*********** Running smoke tests %s Tests **********' % image)
        image_class = "%sTest" % image
        test_class = getattr(__import__('SmokeTests', fromlist=[smoke_test_class]), smoke_test_class)
        suite = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e.message)
        failed = True

    try:
        # Run Selenium tests
        logger.info('*********** Running Selenium tests %s Tests **********' % image)
        test_class = getattr(__import__('SeleniumTests', fromlist=[TEST_NAME_MAP[image]]), TEST_NAME_MAP[image])
        suite = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e.message)
        failed = True

    logger.info("Cleaning up...")

    test_container = client.containers.get(test_container_id)
    test_container.kill()
    test_container.remove()

    if standalone:
        logger.info("Standalone Cleaned up")
    else:
        #Kill the launched hub
        hub = client.containers.get(hub_id)
        hub.kill()
        hub.remove()
        logger.info("Hub / Node Cleaned up")

    if failed:
        exit(1)
