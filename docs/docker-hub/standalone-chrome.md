---
description: Selenium Grid in Standalone mode with Chrome
---
# Selenium Grid Standalone with Chrome

### This image provides a [Selenium Grid Standalone](https://www.selenium.dev/documentation/grid/getting_started/#standalone) with Chrome, which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

## How to run this image

1. Start a Standalone Chrome

```bash
docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-chrome:latest
```

2. Point your WebDriver tests to http://localhost:4444

3. That's it! 

4. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>.

* When executing `docker run` for an image that contains a browser please use the flag `--shm-size=2g` to use the host's shared memory.
  
* The example above uses `latest` as a tag, but we recommend to full tag to pin a specific browser and Grid version. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/standalone-chrome-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Also with browser version and browser driver version

```
selenium/standalone-chrome-<browserVersion>-<browserDriver>-<browserDriverVersion>-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```
Plus all the permutations from the above one

### Example of a release with Chrome 152, ChromeDriver 152.0 and Selenium Grid Server 4.48.0, released on 20260909

```
    Chrome 152.0
    ChromeDriver 152.0
    Selenium Server 4.48.0
    Release date 20260909


e126989f151e        selenium/standalone-chrome   4
e126989f151e        selenium/standalone-chrome   4.48
e126989f151e        selenium/standalone-chrome   4.48.0
e126989f151e        selenium/standalone-chrome   4.48.0-20260909
e126989f151e        selenium/standalone-chrome   152.0                  
e126989f151e        selenium/standalone-chrome   152.0-20260909         
e126989f151e        selenium/standalone-chrome   152.0-chromedriver-152.0 
e126989f151e        selenium/standalone-chrome   152.0-chromedriver-152.0-20260909
e126989f151e        selenium/standalone-chrome   152.0-chromedriver-152.0-grid-4.48.0-20260909  
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
