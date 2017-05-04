import os
import docker
import unittest
import logging
import sys

import time
from docker.errors import NotFound

# LOGGING #
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Docker Client
client = docker.from_env()

NAMESPACE = os.environ.get('NAMESPACE')
VERSION = os.environ.get('VERSION')

NAME_MAP = {
    # Hub
    'Hub': 'hub',

    # Chrome Images
    'NodeChrome': 'node-chrome',
    'NodeChromeDebug': 'node-chrome-debug',
    'StandaloneChrome': 'standalone-chrome',

    # Firefox Images
    'NodeFirefox': 'node-firefox',
    'NodeFirefoxDebug': 'node-firefox-debug',
    'StandaloneFirefox': 'standalone-firefox',

    # PhantomJS Images
    'NodePhantomJS': 'node-phantomjs',
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
    client.images.build(path='../%s' % container)
    logger.info("Done building %s" % container)

    # Run the container
    logger.info("Running %s container..." % container)
    container_id = client.containers.run("%s/%s:%s" % (NAMESPACE, NAME_MAP[container], VERSION),
                                         detach=True,
                                         **kwargs).short_id
    logger.info("%s up and running" % container)
    return container_id


if __name__ == '__main__':
    # The container to test against
    image = sys.argv[1]

    if len(sys.argv) > 2:
        standalone = True
    else:
        standalone = False

    # Flag for failure (for posterity)
    failed = False

    if not standalone:
        """
        Hub / Node Configurations
        """
        logger.info('========== Starting %s Container ==========' % image)
        hub_id = launch_hub()
        test_container_id = launch_container(image, links={hub_id: 'hub'})
        logger.info('========== / Containers ready to go ==========')
        try:
            # Hub / Node Tests
            logger.info('*********** Running %s Tests **********' % image)
            image_class = "%sTest" % image
            test_class = getattr(__import__(image, fromlist=[image_class]), image_class)

            suite = unittest.TestLoader().loadTestsFromTestCase(test_class)

            unittest.TextTestRunner(verbosity=3).run(suite)
        except Exception as e:
            logger.fatal(e.message)
            failed = True

        logger.info("Cleaning up...")
        # kill the node and the hub that were launched
        hub = client.containers.get(hub_id)
        node = client.containers.get(test_container_id)

        hub.kill()
        node.kill()

        hub.remove()
        node.remove()

        logger.info("Hub / Node Cleaned up")

        if failed:
            exit(1)
    else:
        """
        Standalone Configurations
        """
        pass
