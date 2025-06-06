import sys
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.edge.options import Options as EdgeOptions

if len(sys.argv) < 2:
    print("Usage: python3 get_started.py [chrome|firefox|edge]")
    sys.exit(1)
browser = sys.argv[1].lower()
if browser not in ["chrome", "firefox", "edge"]:
    print("Unsupported browser. Use 'chrome', 'firefox', or 'edge'.")
    sys.exit(1)

if len(sys.argv) > 2:
    GRID_URL = sys.argv[2]
else:
    GRID_URL = "http://localhost:4444/wd/hub"

import concurrent.futures

def run_browser_instance(browser, grid_url):
    options = None
    if browser == "chrome":
        options = ChromeOptions()
    elif browser == "firefox":
        options = FirefoxOptions()
    elif browser == "edge":
        options = EdgeOptions()
    options.enable_bidi = True
    options.enable_downloads = False

    while True:
        driver = webdriver.Remote(
            command_executor=grid_url,
            options=options,
        )
        driver.get('https://www.google.com/')
        print(driver.title)
        time.sleep(100)
        driver.quit()

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    for _ in range(3):
        executor.submit(run_browser_instance, browser, GRID_URL)
