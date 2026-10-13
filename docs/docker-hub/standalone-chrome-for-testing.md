---
description: Selenium Grid in Standalone mode with Chrome for Testing (CfT)
---
# Selenium Grid Standalone with Chrome for Testing

### This image provides a [Selenium Grid Standalone](https://www.selenium.dev/documentation/grid/getting_started/#standalone) with [Chrome for Testing](https://developer.chrome.com/blog/chrome-for-testing), which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

Chrome for Testing (CfT) is a Chrome flavour published by the Chrome team specifically for automation. Every CfT build is released together with the exact ChromeDriver built from the same revision, so the browser and the driver in this image are always a known-good pair. Unlike the regular `selenium/standalone-chrome` image, CfT does not auto-update and does not carry the components a consumer browser ships with, which makes it the better choice when you need a build that stays exactly where you pinned it.

* Chrome for Testing is published for `linux64` only, so `selenium/standalone-chrome-for-testing` is available for **linux/amd64** only. On ARM64, use [`selenium/standalone-chrome`](https://hub.docker.com/r/selenium/standalone-chrome) or [`selenium/standalone-chromium`](https://hub.docker.com/r/selenium/standalone-chromium) instead.
* The Grid registers the capability `browserName=chrome`, so existing tests need no change.

## How to run this image

1. Start a Standalone Chrome for Testing

```bash
docker run -d -p 4444:4444 -p 7900:7900 --platform linux/amd64 --shm-size="2g" \
    selenium/standalone-chrome-for-testing:4.48.0-20260905
```

2. Point your WebDriver tests to http://localhost:4444

3. That's it!

4. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>. Port `7900` serves the built-in noVNC session; the default password is `secret`.

* When executing `docker run` for an image that contains a browser please use the flag `--shm-size=2g` to use the host's shared memory. Chrome will crash on the default 64 MB `/dev/shm` otherwise.

* The example above pins a full tag. Pinning a specific browser and Grid version is the recommended way to run these images. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

* Beta, Dev and Canary channels of Chrome for Testing are also published, as `selenium/standalone-chrome-for-testing:beta`, `:dev` and `:canary`.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/standalone-chrome-for-testing-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Also with browser version and browser driver version

```
selenium/standalone-chrome-for-testing-<browserVersion>-<browserDriver>-<browserDriverVersion>-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```
Plus all the permutations from the above one

### Example of a release with Chrome for Testing <BrowserMajor>, ChromeDriver <DriverMajor>.<DriverMinor> and Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Chrome for Testing <BrowserMajor>.<BrowserMinor>
    ChromeDriver <DriverMajor>.<DriverMinor>
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


e126989f151e        selenium/standalone-chrome-for-testing   <Major>
e126989f151e        selenium/standalone-chrome-for-testing   <Major>.<Minor>
e126989f151e        selenium/standalone-chrome-for-testing   <Major>.<Minor>.<Patch>
e126989f151e        selenium/standalone-chrome-for-testing   <Major>.<Minor>.<Patch>-<YYYYMMDD>
e126989f151e        selenium/standalone-chrome-for-testing   <BrowserMajor>.<BrowserMinor>
e126989f151e        selenium/standalone-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-<YYYYMMDD>
e126989f151e        selenium/standalone-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>
e126989f151e        selenium/standalone-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>-<YYYYMMDD>
e126989f151e        selenium/standalone-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>-grid-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
