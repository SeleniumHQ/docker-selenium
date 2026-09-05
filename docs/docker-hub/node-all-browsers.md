---
description: Selenium Grid in Node mode with all popular browsers (Chrome, Edge, Firefox)
---
# Selenium Grid Node with all browsers

### This image provides a single [Selenium Grid Node](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node) with Chrome, Edge and Firefox pre-installed, meant to be used together with a [Selenium Grid Hub](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node), which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

Where `selenium/node-chrome`, `selenium/node-edge` and `selenium/node-firefox` each serve one browser, this image registers stereotypes for all of them at once. A session request matching `browserName=chrome`, `MicrosoftEdge` or `firefox` is served by the same container.

Available from image tag `4.35.0` onwards. It suits you if you:

* prefer a single "all-in-one" container over one Node per browser;
* do not mind the image size — it is considerably larger than a single-browser Node, because it carries three browsers and three drivers;
* run a lightweight workload and are able to size the container's resources yourself.

Browser availability differs per architecture:

| Browser / Arch | x86_64 (aka amd64) | aarch64 (aka arm64/armv8) |
|----------------|--------------------|---------------------------|
| Chrome         | ✅                  | ✅                         |
| Edge           | ✅                  | ❌                         |
| Firefox        | ✅                  | ✅                         |
| Chromium       | ✅                  | ✅                         |

Both the Chrome and the Chromium binary are present on `linux/amd64`, with Chrome activated by default. To switch to Chromium, set `SE_BROWSER_BINARY_LOCATION_CHROME=/usr/bin/chromium`.

## How to run this image

The Hub and Nodes will be created in the same network and they will recognize each other by their container name.
A Docker [network](https://docs.docker.com/engine/reference/commandline/network_create/) needs to be created as a first step.

1. Create a Docker Network

```bash
docker network create grid
```

2. Start the Hub using the created network

```bash
docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:4.48.0-20260909
```

3. Start the Node using the created network

```bash
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="3g" \
    selenium/node-all-browsers:4.48.0-20260909
```

If you are using Windows Powershell, use this command:

```powershell
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub `
    --shm-size="3g" `
    selenium/node-all-browsers:4.48.0-20260909
```

4. Point your WebDriver tests to http://localhost:4444

5. That's it!

6. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>.

* When executing `docker run` for an image that contains a browser please use the flag `--shm-size` to use the host's shared memory. Because this Node can run any of three browsers, `--shm-size=3g` is the recommended starting point.

* The example above pins a full tag. Pinning a specific Grid version is the recommended way to run these images. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

* A more detailed explanation that shows how to run the Nodes in different configurations can be seen at the [Docker-Selenium project in GitHub](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/README.md#hub-and-nodes)

* When you are done using the Grid, and the containers have exited, the network can be removed with the following command:

``` bash
docker network rm grid
```

## How to configure the browsers

Set `SE_NODE_ENABLE_BROWSER_<BROWSER>=false` to stop a browser from being registered, with `<BROWSER>` in uppercase — `CHROME`, `EDGE` or `FIREFOX`. For example, to run this Node without Firefox:

```bash
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="3g" \
    -e SE_NODE_ENABLE_BROWSER_FIREFOX=false \
    selenium/node-all-browsers:4.48.0-20260909
```

The following environment variables accept the same `_<BROWSER>` suffix, so each browser can be configured independently within the one container:

```
SE_NODE_STEREOTYPE
SE_NODE_BROWSER_NAME
SE_NODE_BROWSER_VERSION
SE_NODE_PLATFORM_NAME
SE_BROWSER_BINARY_LOCATION
SE_NODE_STEREOTYPE_EXTRA
SE_NODE_MAX_SESSIONS
```

The full list of environment variables is documented in [ENV_VARIABLES.md](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/ENV_VARIABLES.md).

## How to choose the correct tag for you

This image is tagged with the Selenium Grid version only — there is no per-browser tag, since it carries several browsers at once.

```
selenium/node-all-browsers-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

### Example of a release with Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


e126989f151e        selenium/node-all-browsers   <Major>
e126989f151e        selenium/node-all-browsers   <Major>.<Minor>
e126989f151e        selenium/node-all-browsers   <Major>.<Minor>.<Patch>
e126989f151e        selenium/node-all-browsers   <Major>.<Minor>.<Patch>-<YYYYMMDD>
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
