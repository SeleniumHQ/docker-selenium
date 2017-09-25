import unittest
import urllib2
import time
import json


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
                response = urllib2.urlopen('http://localhost:%s/wd/hub/status' % port)
                status_json = json.loads(response.read())
                self.assertTrue(status_json['value']['ready'], "Container is not ready on port %s" % port)
                status_fetched = True
            except Exception as e:
                time.sleep(sleep_interval)

        self.assertTrue(status_fetched, "Container status was not fetched on port %s" % port)
        self.assertTrue(status_json['status'] == 0, "Wrong status value for container on port %s" % port)
        self.assertTrue(status_json['value']['ready'], "Container is not ready on port %s" % port)


class NodeTest(SmokeTests):
    def test_hub_and_node_up(self):
        self.smoke_test_container(4444)
        self.smoke_test_container(5555)


class StandaloneTest(SmokeTests):
    def test_standalone_up(self):
        self.smoke_test_container(4444)
