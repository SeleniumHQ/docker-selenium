import os
import unittest
import time
import json

try:
    from urllib2 import urlopen
except ImportError:
    from urllib.request import urlopen

SELENIUM_GRID_HOST = os.environ.get('SELENIUM_GRID_HOST', 'localhost')


class SmokeTests(unittest.TestCase):
    def smoke_test_container(self, port):
        current_attempts = 0
        max_attempts = 3
        sleep_interval = 3
        status_fetched = False
        status_json = None

        while current_attempts < max_attempts:
            current_attempts = current_attempts + 1
            try:
                response = urlopen('http://%s:%s/status' % (SELENIUM_GRID_HOST, port))
                status_json = json.loads(response.read())
                self.assertTrue(status_json['value']['ready'], "Container is not ready on port %s" % port)
                status_fetched = True
            except Exception as e:
                time.sleep(sleep_interval)

        self.assertTrue(status_fetched, "Container status was not fetched on port %s" % port)
        self.assertTrue(status_json['value']['ready'], "Container is not ready on port %s" % port)


class GridTest(SmokeTests):
    def test_grid_is_up(self):
        self.smoke_test_container(4444)
