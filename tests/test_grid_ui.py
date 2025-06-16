import sys
import time

from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

if len(sys.argv) < 2:
    print("Usage: python3 get_started.py [chrome|firefox|edge]")
    sys.exit(1)
browser = sys.argv[1].lower()
if browser not in ["chrome", "firefox", "edge"]:
    print("Unsupported browser. Use 'chrome', 'firefox', or 'edge'.")
    sys.exit(1)


def run_browser_instance(browser):

    while True:
        options = None
        if browser == "chrome":
            options = ChromeOptions()
            options.add_argument("--headless=new")
            driver = webdriver.Chrome(options=options)
        elif browser == "firefox":
            options = FirefoxOptions()
            driver = webdriver.Firefox(options=options)
        elif browser == "edge":
            options = EdgeOptions()
            driver = webdriver.Edge(options=options)
        else:
            raise ValueError("Unsupported browser. Use 'chrome', 'firefox', or 'edge'.")

        try:
            driver.get('http://localhost:4444')
            print(driver.title)

            # Explicit wait for the search bar to be visible
            WebDriverWait(driver, 10).until(
                EC.visibility_of_element_located((By.XPATH, "//*[@data-testid='VideocamIcon']/.."))
            )

            import random

            elements = driver.find_elements(By.XPATH, "//*[@data-testid='VideocamIcon']/..")
            if elements:
                random.choice(elements).click()
                print("Random element clicked.")
            else:
                print("No elements found.")
        finally:
            time.sleep(15)  # Keep the browser open for 10 seconds
            driver.quit()


import concurrent.futures

with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    for _ in range(5):
        executor.submit(run_browser_instance, browser)
