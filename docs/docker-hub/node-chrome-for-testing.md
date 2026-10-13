---
description: Selenium Grid in Node mode with Chrome for Testing (CfT)
---
# Selenium Grid Node with Chrome for Testing

### This image provides a [Selenium Grid Node](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node) with [Chrome for Testing](https://developer.chrome.com/blog/chrome-for-testing), meant to be used together with a [Selenium Grid Hub](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node), which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

Chrome for Testing (CfT) is a Chrome flavour published by the Chrome team specifically for automation. Every CfT build is released together with the exact ChromeDriver built from the same revision, so the browser and the driver in this image are always a known-good pair. Unlike the regular `selenium/node-chrome` image, CfT does not auto-update and does not carry the components a consumer browser ships with, which makes it the better choice when you need a build that stays exactly where you pinned it.

* Chrome for Testing is published for `linux64` only, so `selenium/node-chrome-for-testing` is available for **linux/amd64** only. On ARM64, use [`selenium/node-chrome`](https://hub.docker.com/r/selenium/node-chrome) or [`selenium/node-chromium`](https://hub.docker.com/r/selenium/node-chromium) instead.
* The Node registers with the capability `browserName=chrome`, so existing tests need no change.

## How to run this image

The Hub and Nodes will be created in the same network and they will recognize each other by their container name.
A Docker [network](https://docs.docker.com/engine/reference/commandline/network_create/) needs to be created as a first step.

1. Create a Docker Network

```bash
docker network create grid
```

2. Start the Hub using the created network

```bash
docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:4.48.0-20260905
```

3. Start the Node using the created network

```bash
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --platform linux/amd64 \
    --shm-size="2g" \
    selenium/node-chrome-for-testing:4.48.0-20260905
```

If you are using Windows Powershell, use this command:

```powershell
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub `
    --platform linux/amd64 `
    --shm-size="2g" `
    selenium/node-chrome-for-testing:4.48.0-20260905
```

4. Point your WebDriver tests to http://localhost:4444

5. That's it!

6. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>.

* When executing `docker run` for an image that contains a browser please use the flag `--shm-size=2g` to use the host's shared memory.

* The example above pins a full tag. Pinning a specific browser and Grid version is the recommended way to run these images. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

* Beta, Dev and Canary channels of Chrome for Testing are also published, as `selenium/node-chrome-for-testing:beta`, `:dev` and `:canary`.

* A more detailed explanation that shows how to run the Nodes in different configurations can be seen at the [Docker-Selenium project in GitHub](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/README.md#hub-and-nodes)

* When you are done using the Grid, and the containers have exited, the network can be removed with the following command:

``` bash
docker network rm grid
```

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/node-chrome-for-testing-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Also with browser version and browser driver version

```
selenium/node-chrome-for-testing-<browserVersion>-<browserDriver>-<browserDriverVersion>-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```
Plus all the permutations from the above one

### Example of a release with Chrome for Testing <BrowserMajor>, ChromeDriver <DriverMajor>.<DriverMinor> and Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Chrome for Testing <BrowserMajor>.<BrowserMinor>
    ChromeDriver <DriverMajor>.<DriverMinor>
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


e126989f151e        selenium/node-chrome-for-testing   <Major>
e126989f151e        selenium/node-chrome-for-testing   <Major>.<Minor>
e126989f151e        selenium/node-chrome-for-testing   <Major>.<Minor>.<Patch>
e126989f151e        selenium/node-chrome-for-testing   <Major>.<Minor>.<Patch>-<YYYYMMDD>
e126989f151e        selenium/node-chrome-for-testing   <BrowserMajor>.<BrowserMinor>
e126989f151e        selenium/node-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-<YYYYMMDD>
e126989f151e        selenium/node-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>
e126989f151e        selenium/node-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>-<YYYYMMDD>
e126989f151e        selenium/node-chrome-for-testing   <BrowserMajor>.<BrowserMinor>-chromedriver-<DriverMajor>.<DriverMinor>-grid-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
