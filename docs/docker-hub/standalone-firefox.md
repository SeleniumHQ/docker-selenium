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

### Example of a release with Firefox 110, GeckoDriver 0.33.0 and Selenium Grid Server 4.9.0, released on 20230426

```
    Firefox 111.0
    GeckoDriver 0.33.0
    Selenium Server 4.9.0
    Release date 20230426


e126989f151e        selenium/standalone-firefox   4
e126989f151e        selenium/standalone-firefox   4.9
e126989f151e        selenium/standalone-firefox   4.9.0
e126989f151e        selenium/standalone-firefox   4.9.0-20230426
e126989f151e        selenium/standalone-firefox   110.0                  
e126989f151e        selenium/standalone-firefox   110.0-20230426         
e126989f151e        selenium/standalone-firefox   110.0-geckodriver-0.33.0 
e126989f151e        selenium/standalone-firefox   110.0-geckodriver-0.33.0-20230426
e126989f151e        selenium/standalone-firefox   110.0-geckodriver-0.33.0-grid-4.9.0-20230426  
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
