---
description: Selenium Grid in Standalone mode with Firefox
---
# Selenium Grid Standalone with Firefox

### This image provides a [Selenium Grid Standalone](https://www.selenium.dev/documentation/grid/getting_started/#standalone) with Firefox, which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

## How to run this image

1. Start a Standalone Firefox Firefox

```bash
docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-firefox:latest
```

2. Point your WebDriver tests to http://localhost:4444

3. That's it! 

4. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>.

* When executing `docker run` for an image that contains a browser please use the flag `--shm-size=2g` to use the host's shared memory.
  
* The example above uses `latest` as a tag, but we recommend to full tag to pin a specific browser and Grid version. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/standalone-firefox-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Also with browser version and browser driver version

```
selenium/standalone-firefox-<browserVersion>-<browserDriver>-<browserDriverVersion>-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```
Plus all the permutations from the above one

### Example of a release with Firefox <BrowserMajor>, GeckoDriver <GeckoDriverMajor>.<GeckoDriverMinor> and Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Firefox <BrowserMajor>.<BrowserMinor>
    GeckoDriver <GeckoDriverMajor>.<GeckoDriverMinor>
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


e126989f151e        selenium/standalone-firefox   <Major>
e126989f151e        selenium/standalone-firefox   <Major>.<Minor>
e126989f151e        selenium/standalone-firefox   <Major>.<Minor>.<Patch>
e126989f151e        selenium/standalone-firefox   <Major>.<Minor>.<Patch>-<YYYYMMDD>
e126989f151e        selenium/standalone-firefox   <BrowserMajor>.<BrowserMinor>
e126989f151e        selenium/standalone-firefox   <BrowserMajor>.<BrowserMinor>-<YYYYMMDD>
e126989f151e        selenium/standalone-firefox   <BrowserMajor>.<BrowserMinor>-geckodriver-<GeckoDriverMajor>.<GeckoDriverMinor>
e126989f151e        selenium/standalone-firefox   <BrowserMajor>.<BrowserMinor>-geckodriver-<GeckoDriverMajor>.<GeckoDriverMinor>-<YYYYMMDD>
e126989f151e        selenium/standalone-firefox   <BrowserMajor>.<BrowserMinor>-geckodriver-<GeckoDriverMajor>.<GeckoDriverMinor>-grid-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
