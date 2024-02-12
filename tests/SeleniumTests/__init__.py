import unittest
import concurrent.futures
import os
import traceback
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.chrome.options import Options as ChromeOptions

SELENIUM_GRID_PROTOCOL = os.environ.get('SELENIUM_GRID_PROTOCOL', 'http')
SELENIUM_GRID_HOST = os.environ.get('SELENIUM_GRID_HOST', 'localhost')
SELENIUM_GRID_PORT = os.environ.get('SELENIUM_GRID_PORT', '4444')
SELENIUM_GRID_TEST_HEADLESS = os.environ.get('SELENIUM_GRID_TEST_HEADLESS', 'false').lower() == 'true'
WEB_DRIVER_WAIT_TIMEOUT = int(os.environ.get('WEB_DRIVER_WAIT_TIMEOUT', 60))

class SeleniumGenericTests(unittest.TestCase):

    def test_title(self):
        self.driver.get('https://the-internet.herokuapp.com')
        self.assertTrue(self.driver.title == 'The Internet')

    # https://github.com/tourdedave/elemental-selenium-tips/blob/master/03-work-with-frames/python/frames.py
    def test_with_frames(self):
        driver = self.driver
        driver.get('http://the-internet.herokuapp.com/nested_frames')
        wait = WebDriverWait(driver, WEB_DRIVER_WAIT_TIMEOUT)
        frame_top = wait.until(
            EC.frame_to_be_available_and_switch_to_it('frame-top')
        )
        frame_middle = wait.until(
            EC.frame_to_be_available_and_switch_to_it('frame-middle')
        )
        self.assertTrue(driver.find_element(By.ID, 'content').text == "MIDDLE", "content should be MIDDLE")

    # https://github.com/tourdedave/elemental-selenium-tips/blob/master/05-select-from-a-dropdown/python/dropdown.py
    def test_select_from_a_dropdown(self):
        driver = self.driver
        driver.get('http://the-internet.herokuapp.com/dropdown')
        dropdown_list = driver.find_element(By.ID, 'dropdown')
        options = dropdown_list.find_elements(By.TAG_NAME, 'option')
        for opt in options:
            if opt.text == 'Option 1':
                opt.click()
                break
        for opt in options:
            if opt.is_selected():
                selected_option = opt.text
                break
        self.assertTrue(selected_option == 'Option 1', "Selected option should be Option 1")

    # https://github.com/tourdedave/elemental-selenium-tips/blob/master/13-work-with-basic-auth/python/basic_auth_1.py
    def test_visit_basic_auth_secured_page(self):
        driver = self.driver
        driver.get('http://admin:admin@the-internet.herokuapp.com/basic_auth')
        page_message = driver.find_element(By.CSS_SELECTOR, '.example p').text
        self.assertTrue(page_message == 'Congratulations! You must have the proper credentials.')

    def test_play_video(self):
        driver = self.driver
        driver.get('https://hls-js.netlify.com/demo/')
        wait = WebDriverWait(driver, WEB_DRIVER_WAIT_TIMEOUT)
        video = wait.until(
            EC.element_to_be_clickable((By.TAG_NAME, 'video'))
        )
        video.click()
        wait.until(
            lambda d: d.find_element(By.TAG_NAME, 'video').get_property('currentTime')
        )
        paused = video.get_property('paused')
        self.assertFalse(paused)

    def test_download_file(self):
        driver = self.driver
        driver.get('https://the-internet.herokuapp.com/download')
        file_name = 'some-file.txt'
        is_continue = True
        wait = WebDriverWait(driver, 30)
        file_link = wait.until(
            EC.element_to_be_clickable((By.LINK_TEXT, file_name))
        )
        file_link.click()
        wait.until(
            lambda d: str(d.get_downloadable_files()[0]).endswith(file_name)
        )
        self.assertTrue(str(driver.get_downloadable_files()[0]).endswith(file_name))

    def tearDown(self):
        self.driver.quit()


class ChromeTests(SeleniumGenericTests):
    def setUp(self):
        options = ChromeOptions()
        options.enable_downloads = True
        options.add_argument('disable-features=DownloadBubble,DownloadBubbleV2')
        options.set_capability('se:recordVideo', True)
        if SELENIUM_GRID_TEST_HEADLESS:
            options.add_argument('--headless=new')
        self.driver = webdriver.Remote(
            options=options,
            command_executor="%s://%s:%s" % (SELENIUM_GRID_PROTOCOL,SELENIUM_GRID_HOST,SELENIUM_GRID_PORT)
        )

class EdgeTests(SeleniumGenericTests):
    def setUp(self):
        options = EdgeOptions()
        options.enable_downloads = True
        options.add_argument('disable-features=DownloadBubble,DownloadBubbleV2')
        options.set_capability('se:recordVideo', True)
        if SELENIUM_GRID_TEST_HEADLESS:
            options.add_argument('--headless=new')
        self.driver = webdriver.Remote(
            options=options,
            command_executor="%s://%s:%s" % (SELENIUM_GRID_PROTOCOL,SELENIUM_GRID_HOST,SELENIUM_GRID_PORT)
        )


class FirefoxTests(SeleniumGenericTests):
    def setUp(self):
        profile = webdriver.FirefoxProfile()
        profile.set_preference("browser.download.manager.showWhenStarting", False)
        profile.set_preference("browser.helperApps.neverAsk.saveToDisk", "*/*")
        options = FirefoxOptions()
        options.profile = profile
        options.enable_downloads = True
        options.set_capability('se:recordVideo', True)
        if SELENIUM_GRID_TEST_HEADLESS:
            options.add_argument('-headless')
        self.driver = webdriver.Remote(
            options=options,
            command_executor="%s://%s:%s" % (SELENIUM_GRID_PROTOCOL,SELENIUM_GRID_HOST,SELENIUM_GRID_PORT)
        )

    def test_title_and_maximize_window(self):
        self.driver.get('https://the-internet.herokuapp.com')
        self.driver.maximize_window()
        self.assertTrue(self.driver.title == 'The Internet')

class Autoscaling():
    def run(self, test_classes):
        with concurrent.futures.ThreadPoolExecutor() as executor:
            futures = []
            tests = []
            for test_class in test_classes:
                suite = unittest.TestLoader().loadTestsFromTestCase(test_class)
                for test in suite:
                    futures.append(executor.submit(test))
                    tests.append(test)
            failed_tests = []
            for future, test in zip(concurrent.futures.as_completed(futures), tests):
                try:
                    if not future.result().wasSuccessful():
                        raise Exception
                except Exception as e:
                    failed_tests.append(test)
                    print(traceback.format_exc())
                    print(f"{str(test)} failed with exception: {str(e)}")
                    print(f"Original exception: {e.__cause__}")
            if len(failed_tests) > 0:
                print(f"Number of failed tests: {len(failed_tests)}. Going to rerun!")
                for test in failed_tests:
                    try:
                        print(f"Rerunning test: {str(test)}")
                        rerun_result = test.run()
                        if not rerun_result.wasSuccessful():
                            raise Exception
                    except Exception as e:
                        print(traceback.format_exc())
                        print(f"Test {str(test)} failed again with exception: {str(e)}")
                        print(f"Original exception: {e.__cause__}")
                        raise Exception(f"Rerun test failed: {str(test)} failed with exception: {str(e)}")
                print(f"::warning:: Number of failed tests: {len(failed_tests)}. All tests passed in rerun!")

class DeploymentAutoscalingTests(unittest.TestCase):
    def test_parallel_autoscaling(self):
        runner = Autoscaling()
        runner.run([FirefoxTests, EdgeTests, ChromeTests])

class JobAutoscalingTests(unittest.TestCase):
    def test_parallel_autoscaling(self):
        runner = Autoscaling()
        runner.run([FirefoxTests, EdgeTests, ChromeTests])
