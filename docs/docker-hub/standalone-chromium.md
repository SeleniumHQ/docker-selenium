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

### Example of a release with chromium 125, ChromeDriver 125.0 and Selenium Grid Server 4.21.0, released on 20240522

```
    Chromium 125.0
    ChromeDriver 125.0
    Selenium Server 4.21.0
    Release date 20240522


2cef49b284b5   selenium/standalone-chromium   125.0                                                           
2cef49b284b5   selenium/standalone-chromium   125.0-20240522                                                  
2cef49b284b5   selenium/standalone-chromium   125.0-chromedriver-125.0                                        
2cef49b284b5   selenium/standalone-chromium   125.0-chromedriver-125.0-20240522                               
2cef49b284b5   selenium/standalone-chromium   125.0-chromedriver-125.0-grid-4.21.0-20240522                   
2cef49b284b5   selenium/standalone-chromium   125.0.6422.60                                                   
2cef49b284b5   selenium/standalone-chromium   125.0.6422.60-20240522                                          
2cef49b284b5   selenium/standalone-chromium   125.0.6422.60-chromedriver-125.0.6422.60                        
2cef49b284b5   selenium/standalone-chromium   125.0.6422.60-chromedriver-125.0.6422.60-20240522               
2cef49b284b5   selenium/standalone-chromium   125.0.6422.60-chromedriver-125.0.6422.60-grid-4.21.0-20240522   
2cef49b284b5   selenium/standalone-chromium   4                                                               
2cef49b284b5   selenium/standalone-chromium   4.21                                                            
2cef49b284b5   selenium/standalone-chromium   4.21.0                                                          
2cef49b284b5   selenium/standalone-chromium   4.21.0-20240522                                                 
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
