import unittest
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.chrome.options import Options as ChromeOptions

SELENIUM_GRID_HOST = os.environ.get('SELENIUM_GRID_HOST', 'localhost')


class SeleniumGenericTests(unittest.TestCase):

    def test_title(self):
        self.driver.get('https://the-internet.herokuapp.com')
        self.assertTrue(self.driver.title == 'The Internet')

    # https://github.com/tourdedave/elemental-selenium-tips/blob/master/03-work-with-frames/python/frames.py
    def test_with_frames(self):
        driver = self.driver
        driver.get('http://the-internet.herokuapp.com/nested_frames')
        driver.switch_to.frame('frame-top')
        driver.switch_to.frame('frame-middle')
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
        wait = WebDriverWait(driver, 30)
        video = wait.until(
            EC.element_to_be_clickable((By.TAG_NAME, 'video'))
        )
        video.click()
        wait.until(
            lambda d: d.find_element(By.TAG_NAME, 'video').get_property('currentTime')
        )
        paused = video.get_property('paused')
        self.assertFalse(paused)

    def tearDown(self):
        self.driver.quit()


class ChromeTests(SeleniumGenericTests):
    def setUp(self):
        self.driver = webdriver.Remote(
            options=ChromeOptions(),
            command_executor="http://%s:4444" % SELENIUM_GRID_HOST
        )

class EdgeTests(SeleniumGenericTests):
    def setUp(self):
        self.driver = webdriver.Remote(
            options=EdgeOptions(),
            command_executor="http://%s:4444" % SELENIUM_GRID_HOST
        )


class FirefoxTests(SeleniumGenericTests):
    def setUp(self):
        self.driver = webdriver.Remote(
            options=FirefoxOptions(),
            command_executor="http://%s:4444" % SELENIUM_GRID_HOST
        )

    def test_title_and_maximize_window(self):
        self.driver.get('https://the-internet.herokuapp.com')
        self.driver.maximize_window()
        self.assertTrue(self.driver.title == 'The Internet')
