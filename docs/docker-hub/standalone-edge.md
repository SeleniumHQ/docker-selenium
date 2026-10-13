---
description: Selenium Grid in Standalone mode with Edge
---
# Selenium Grid Standalone with Edge

### This image provides a [Selenium Grid Standalone](https://www.selenium.dev/documentation/grid/getting_started/#standalone) with Edge, which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

## How to run this image

1. Start a Standalone Edge

```bash
docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-edge:latest
```

2. Point your WebDriver tests to http://localhost:4444

3. That's it! 

4. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>.

* When executing `docker run` for an image that contains a browser please use the flag `--shm-size=2g` to use the host's shared memory.
  
* The example above uses `latest` as a tag, but we recommend to full tag to pin a specific browser and Grid version. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/standalone-edge-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Also with browser version and browser driver version

```
selenium/standalone-edge-<browserVersion>-<browserDriver>-<browserDriverVersion>-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```
Plus all the permutations from the above one

### Example of a release with Edge <BrowserMajor>, EdgeDriver <DriverMajor>.<DriverMinor> and Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Edge <BrowserMajor>.<BrowserMinor>
    EdgeDriver <DriverMajor>.<DriverMinor>
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


e126989f151e        selenium/standalone-edge   <Major>
e126989f151e        selenium/standalone-edge   <Major>.<Minor>
e126989f151e        selenium/standalone-edge   <Major>.<Minor>.<Patch>
e126989f151e        selenium/standalone-edge   <Major>.<Minor>.<Patch>-<YYYYMMDD>
e126989f151e        selenium/standalone-edge   <BrowserMajor>.<BrowserMinor>
e126989f151e        selenium/standalone-edge   <BrowserMajor>.<BrowserMinor>-<YYYYMMDD>
e126989f151e        selenium/standalone-edge   <BrowserMajor>.<BrowserMinor>-edgedriver-<DriverMajor>.<DriverMinor>
e126989f151e        selenium/standalone-edge   <BrowserMajor>.<BrowserMinor>-edgedriver-<DriverMajor>.<DriverMinor>-<YYYYMMDD>
e126989f151e        selenium/standalone-edge   <BrowserMajor>.<BrowserMinor>-edgedriver-<DriverMajor>.<DriverMinor>-grid-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
