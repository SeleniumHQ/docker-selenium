import unittest
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities


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
        self.assertTrue(driver.find_element_by_id('content').text == "MIDDLE", "content should be MIDDLE")

    # https://github.com/tourdedave/elemental-selenium-tips/blob/master/04-work-with-multiple-windows/python/windows.py
    def test_with_windows(self):
        driver = self.driver
        driver.get('http://the-internet.herokuapp.com/windows')
        driver.find_element_by_css_selector('.example a').click()
        driver.switch_to_window(driver.window_handles[0])
        self.assertTrue(driver.title != "New Window", "title should not be New Window")
        driver.switch_to_window(driver.window_handles[-1])
        self.assertTrue(driver.title == "New Window", "title should be New Window")

    # https://github.com/tourdedave/elemental-selenium-tips/blob/master/13-work-with-basic-auth/python/basic_auth_1.py
    def test_visit_basic_auth_secured_page(self):
        driver = self.driver
        driver.get('http://admin:admin@the-internet.herokuapp.com/basic_auth')
        page_message = driver.find_element_by_css_selector('.example p').text
        self.assertTrue(page_message == 'Congratulations! You must have the proper credentials.')

    def tearDown(self):
        self.driver.quit()


class ChromeTests(SeleniumGenericTests):
    def setUp(self):
        self.driver = webdriver.Remote(
            desired_capabilities=DesiredCapabilities.CHROME
        )


class FirefoxTests(SeleniumGenericTests):
    def setUp(self):
        self.driver = webdriver.Remote(
            desired_capabilities=DesiredCapabilities.FIREFOX
        )
