---
description: Selenium Grid in SessionQueue mode
---
# Selenium Grid SessionQueue in Docker

### This image provides a [Selenium Grid SessionQueue](https://www.selenium.dev/documentation/grid/getting_started/#distributed), meant to be used together with the rest of the components of a [Distributed Grid](https://www.selenium.dev/documentation/grid/getting_started/#distributed). All these components together enable you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

## Selenium Grid Distributed Mode

The distributed mode is thought for [large Grids](https://www.selenium.dev/documentation/grid/getting_started/#large), because it is possible to provide CPU and RAM resources in a more fine grained way for better tuning. 

## How to run this image

It is meant to be run together with the rest of the Distributed components. Given that a Distributed Grid is composed by at least 6 different images (Router, Session Queue, Distributor, Event Bus, Session Map, and Nodes), the example will be shown through a `docker-compose.yml` file for simplicity.

```yml
# To execute this docker-compose yml file use `docker-compose -f docker-compose-v3-full-grid.yml up`
# Add the `-d` flag at the end for detached execution
# To stop the execution, hit Ctrl+C, and then `docker-compose -f docker-compose-v3-full-grid.yml down`
version: "3"
services:
  selenium-event-bus:
    image: selenium/event-bus:latest
    container_name: selenium-event-bus
    ports:
      - "4442:4442"
      - "4443:4443"
      - "5557:5557"

  selenium-sessions:
    image: selenium/sessions:latest
    container_name: selenium-sessions
    ports:
      - "5556:5556"
    depends_on:
      - selenium-event-bus
    environment:
      - SE_EVENT_BUS_HOST=selenium-event-bus
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443

  selenium-session-queue:
    image: selenium/session-queue:latest
    container_name: selenium-session-queue
    ports:
      - "5559:5559"

  selenium-distributor:
    image: selenium/distributor:latest
    container_name: selenium-distributor
    ports:
      - "5553:5553"
    depends_on:
      - selenium-event-bus
      - selenium-sessions
      - selenium-session-queue
    environment:
      - SE_EVENT_BUS_HOST=selenium-event-bus
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_SESSIONS_MAP_HOST=selenium-sessions
      - SE_SESSIONS_MAP_PORT=5556
      - SE_SESSION_QUEUE_HOST=selenium-session-queue
      - SE_SESSION_QUEUE_PORT=5559

  selenium-router:
    image: selenium/router:latest
    container_name: selenium-router
    ports:
      - "4444:4444"
    depends_on:
      - selenium-distributor
      - selenium-sessions
      - selenium-session-queue
    environment:
      - SE_DISTRIBUTOR_HOST=selenium-distributor
      - SE_DISTRIBUTOR_PORT=5553
      - SE_SESSIONS_MAP_HOST=selenium-sessions
      - SE_SESSIONS_MAP_PORT=5556
      - SE_SESSION_QUEUE_HOST=selenium-session-queue
      - SE_SESSION_QUEUE_PORT=5559

  chrome:
    image: selenium/node-chrome:latest
    shm_size: 2gb
    depends_on:
      - selenium-event-bus
    environment:
      - SE_EVENT_BUS_HOST=selenium-event-bus
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443

  edge:
    image: selenium/node-edge:latest
    shm_size: 2gb
    depends_on:
      - selenium-event-bus
    environment:
      - SE_EVENT_BUS_HOST=selenium-event-bus
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443

  firefox:
    image: selenium/node-firefox:latest
    shm_size: 2gb
    depends_on:
      - selenium-event-bus
    environment:
      - SE_EVENT_BUS_HOST=selenium-event-bus
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
```

After starting the complete compose file, point your WebDriver tests to http://localhost:4444.

* The example above uses `latest` as a tag, but we recommend to full tag to pin a specific browser and Grid version. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/session-queue-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

### Example of a release with Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


e126989f151e        selenium/session-queue   <Major>
e126989f151e        selenium/session-queue   <Major>.<Minor>
e126989f151e        selenium/session-queue   <Major>.<Minor>.<Patch>
e126989f151e        selenium/session-queue   <Major>.<Minor>.<Patch>-<YYYYMMDD>
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
