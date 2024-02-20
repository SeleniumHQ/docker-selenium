import os
import unittest
import time
import json
from ssl import _create_unverified_context
import requests
from requests.auth import HTTPBasicAuth

SELENIUM_GRID_PROTOCOL = os.environ.get('SELENIUM_GRID_PROTOCOL', 'http')
SELENIUM_GRID_HOST = os.environ.get('SELENIUM_GRID_HOST', 'localhost')
SELENIUM_GRID_PORT = os.environ.get('SELENIUM_GRID_PORT', '4444')
SELENIUM_GRID_USERNAME = os.environ.get('SELENIUM_GRID_USERNAME', '')
SELENIUM_GRID_PASSWORD = os.environ.get('SELENIUM_GRID_PASSWORD', '')
SELENIUM_GRID_AUTOSCALING = os.environ.get('SELENIUM_GRID_AUTOSCALING', 'false')
SELENIUM_GRID_AUTOSCALING_MIN_REPLICA = os.environ.get('SELENIUM_GRID_AUTOSCALING_MIN_REPLICA', 0)
HUB_CHECKS_MAX_ATTEMPTS = os.environ.get('HUB_CHECKS_MAX_ATTEMPTS', 3)
HUB_CHECKS_INTERVAL = os.environ.get('HUB_CHECKS_INTERVAL', 10)

class SmokeTests(unittest.TestCase):
    def smoke_test_container(self, port):
        current_attempts = 0
        max_attempts = int(HUB_CHECKS_MAX_ATTEMPTS)
        sleep_interval = int(HUB_CHECKS_INTERVAL)
        status_fetched = False
        status_json = None
        auto_scaling = SELENIUM_GRID_AUTOSCALING == 'true'
        auto_scaling_min_replica = int(SELENIUM_GRID_AUTOSCALING_MIN_REPLICA)

        while current_attempts < max_attempts:
            current_attempts = current_attempts + 1
            try:
                grid_url_status = '%s://%s:%s/status' % (SELENIUM_GRID_PROTOCOL, SELENIUM_GRID_HOST, port)
                if SELENIUM_GRID_USERNAME and SELENIUM_GRID_PASSWORD:
                    response = requests.get(grid_url_status, auth=HTTPBasicAuth(SELENIUM_GRID_USERNAME, SELENIUM_GRID_PASSWORD))
                else:
                    response = requests.get(grid_url_status)
                status_json = response.json()
                if not auto_scaling or (auto_scaling and auto_scaling_min_replica > 0):
                    self.assertTrue(status_json['value']['ready'], "Container is not ready on port %s" % port)
                else:
                    self.assertFalse(status_json['value']['ready'], "Container is autoscaling with min replica set to 0")
                status_fetched = True
            except Exception as e:
                time.sleep(sleep_interval)

        if not auto_scaling or (auto_scaling and auto_scaling_min_replica > 0):
            self.assertTrue(status_fetched, "Container status was not fetched on port %s" % port)
            self.assertTrue(status_json['value']['ready'], "Container is not ready on port %s" % port)
        else:
            self.assertFalse(status_json['value']['ready'], "Container is autoscaling with min replica set to 0")


class GridTest(SmokeTests):
    def test_grid_is_up(self):
        self.smoke_test_container('%s' % SELENIUM_GRID_PORT)
