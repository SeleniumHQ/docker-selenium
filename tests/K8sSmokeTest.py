import json
import sys
import time

try:
    from urllib2 import urlopen
except ImportError:
    from urllib.request import urlopen

SELENIUM_GRID_URL = sys.argv[1]
max_attempts = 6
sleep_interval = 10


def get_grid_status():
    try:
        response = urlopen('%s/status' % (SELENIUM_GRID_URL))
        print("Response code: " + str(response.getcode()))
        response = urlopen('%s/status' % (SELENIUM_GRID_URL))
        encoded_response = response.read()
        encoding = response.headers.get_content_charset('utf-8')
        decoded_response = encoded_response.decode(encoding)
        print("Response: " + decoded_response)
        response_json = json.loads(decoded_response)
        return response_json['value']['ready']
    except Exception as e:
        print(e)
        return False


def wait_for_grid_to_get_ready():
    result = get_grid_status()
    ctr=0
    while(not result):
        ctr=ctr+1
        if(ctr>max_attempts):
            print("Timed out. Grid is still not in ready state")
            sys.exit(1)

        print("Grid is not in ready state. Waiting for {0} secs....".format(sleep_interval))
        time.sleep(sleep_interval)
        result = get_grid_status()
    print("Grid Status: " + str(result))
    print("Grid is in Ready state now")


wait_for_grid_to_get_ready()
