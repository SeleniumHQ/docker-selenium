import unittest
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities


class SeleniumGenericTests(unittest.TestCase):
    def test_title(self):
        self.driver.get('https://the-internet.herokuapp.com')
        self.assertTrue(self.driver.title == 'The Internet')

    def test_example_1(self):
        driver = self.driver
        driver.get('http://the-internet.herokuapp.com/nested_frames')
        driver.switch_to.frame('frame-top')
        driver.switch_to.frame('frame-middle')
        self.assertTrue(driver.find_element_by_id('content').text == "MIDDLE", "content should be MIDDLE")

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
