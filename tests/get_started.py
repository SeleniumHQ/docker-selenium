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

options = None
if browser == "chrome":
    options = ChromeOptions()
elif browser == "firefox":
    options = FirefoxOptions()
elif browser == "edge":
    options = EdgeOptions()

driver = webdriver.Remote(
    command_executor=GRID_URL,
    options=options,
)

driver.get('https://www.google.com/')
print(driver.title)
time.sleep(100)
driver.quit()
