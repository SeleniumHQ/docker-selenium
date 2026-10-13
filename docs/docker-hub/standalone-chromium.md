---
description: Selenium Grid in Standalone mode with Chromium
---
# Selenium Grid Standalone with Chromium

### This image provides a [Selenium Grid Standalone](https://www.selenium.dev/documentation/grid/getting_started/#standalone) with Chromium, which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

## How to run this image

1. Start a Standalone Chromium

```bash
docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-chromium:latest
```

2. Point your WebDriver tests to http://localhost:4444

3. That's it! 

4. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>.

* When executing `docker run` for an image that contains a browser please use the flag `--shm-size=2g` to use the host's shared memory.
  
* The example above uses `latest` as a tag, but we recommend to full tag to pin a specific browser and Grid version. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/standalone-chromium-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Also with browser version and browser driver version

```
selenium/standalone-chromium-<browserVersion>-<browserDriver>-<browserDriverVersion>-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```
Plus all the permutations from the above one

### Example of a release with Chromium <BrowserMajor>, ChromeDriver <DriverMajor>.<DriverMinor> and Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Chromium <BrowserMajor>.<BrowserMinor>
    ChromeDriver <DriverMajor>.<DriverMinor>
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


2cef49b284b5   selenium/standalone-chromium   <BrowserMajor>.<BrowserMinor>
2cef49b284b5   selenium/standalone-chromium   <BrowserMajor>.<BrowserMinor>-<YYYYMMDD>
2cef49b284b5   selenium/standalone-chromium   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>
2cef49b284b5   selenium/standalone-chromium   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>-<YYYYMMDD>
2cef49b284b5   selenium/standalone-chromium   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>-grid-<Major>.<Minor>.<Patch>-<YYYYMMDD>
2cef49b284b5   selenium/standalone-chromium   <BrowserFullVersion>
2cef49b284b5   selenium/standalone-chromium   <BrowserFullVersion>-<YYYYMMDD>
2cef49b284b5   selenium/standalone-chromium   <BrowserFullVersion>-chromedriver-<DriverFullVersion>
2cef49b284b5   selenium/standalone-chromium   <BrowserFullVersion>-chromedriver-<DriverFullVersion>-<YYYYMMDD>
2cef49b284b5   selenium/standalone-chromium   <BrowserFullVersion>-chromedriver-<DriverFullVersion>-grid-<Major>.<Minor>.<Patch>-<YYYYMMDD>
2cef49b284b5   selenium/standalone-chromium   <Major>
2cef49b284b5   selenium/standalone-chromium   <Major>.<Minor>
2cef49b284b5   selenium/standalone-chromium   <Major>.<Minor>.<Patch>
2cef49b284b5   selenium/standalone-chromium   <Major>.<Minor>.<Patch>-<YYYYMMDD>
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
