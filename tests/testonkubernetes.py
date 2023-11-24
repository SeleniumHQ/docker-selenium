import logging
import sys
import unittest

# LOGGING #
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

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


if __name__ == '__main__':
    # The container to test against
    image = sys.argv[1]


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

    if failed:
        exit(1)
