[![Build & test](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/build-test.yml/badge.svg)](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/build-test.yml)
[![Deploys](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/deploy.yml/badge.svg)](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/deploy.yml)
[![Release Charts](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/helm-chart-release.yml/badge.svg)](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/helm-chart-release.yml)
[![Nightly](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/nightly.yml/badge.svg)](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/nightly.yml)
[![Update Dev/Beta Browser Images](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/update-dev-beta-browser-images.yml/badge.svg)](https://github.com/SeleniumHQ/docker-selenium/actions/workflows/update-dev-beta-browser-images.yml)
[![Releases downloads](https://img.shields.io/github/downloads/seleniumhq/docker-selenium/total.svg)](https://github.com/SeleniumHQ/docker-selenium/releases)
[<img src="https://devin.ai/assets/deepwiki-badge.png" alt="Ask DeepWiki.com" height="20"/>](https://deepwiki.com/SeleniumHQ/docker-selenium)

# Docker images for the Selenium Grid Server

The project is made possible by volunteer contributors who have put in thousands of hours of their own time, 
and made the source code freely available under the [Apache License 2.0](LICENSE.md).

These Docker images come with a handful of tags to simplify its usage, have a look at them in one of 
our [releases](https://github.com/SeleniumHQ/docker-selenium/releases/tag/4.33.0-20250606).

To get notifications of new releases, add yourself as a "Releases only" watcher. 

These images are published to the Docker Hub registry at [Selenium Docker Hub](https://hub.docker.com/u/selenium).

## Community

Do you need help to use these Docker images?
Talk to us at https://www.selenium.dev/support/

## Contents

<!-- TOC -->
* [Community](#community)
* [Contents](#contents)
* [Quick start](#quick-start)
  * [Try them out in a ready-to-use GitPod environment!](#try-them-out-in-a-ready-to-use-gitpod-environment)
* [Experimental Multi-Arch amd64/aarch64/armhf Images](#experimental-multi-arch-amd64aarch64armhf-images)
* [Nightly Images](#nightly-images)
* [Dev and Beta Channel Browser Images](#dev-and-beta-channel-browser-images)
  * [Dev and Beta Standalone Mode](#dev-and-beta-standalone-mode)
  * [Dev and Beta on the Grid](#dev-and-beta-on-the-grid)
* [Environment Variables](#environment-variables)
* [Execution modes](#execution-modes)
  * [Standalone](#standalone)
  * [Hub and Nodes](#hub-and-nodes)
  * [Fully distributed mode - Router, Queue, Distributor, EventBus, SessionMap and Nodes](#fully-distributed-mode---router-queue-distributor-eventbus-sessionmap-and-nodes)
* [Video recording](#video-recording)
* [Video recording with dynamic file name based on metadata in tests](#video-recording-with-dynamic-file-name-based-on-metadata-in-tests)
* [Video recording and uploading](#video-recording-and-uploading)
* [Dynamic Grid](#dynamic-grid)
  * [Configuration example](#configuration-example)
  * [Share volumes config of Dynamic Grid container to node browser containers](#share-volumes-config-of-dynamic-grid-container-to-node-browser-containers)
  * [Execution with Hub & Node roles](#execution-with-hub--node-roles)
  * [Execution with Standalone roles](#execution-with-standalone-roles)
  * [Using Dynamic Grid in different machines/VMs](#using-dynamic-grid-in-different-machinesvms)
  * [Execution with Docker Compose](#execution-with-docker-compose)
  * [Configuring the child containers](#configuring-the-child-containers)
  * [Video recording, screen resolution, and time zones in a Dynamic Grid](#video-recording-screen-resolution-and-time-zones-in-a-dynamic-grid)
  * [Time zone configuration via env variable](#time-zone-configuration-via-env-variable)
* [Deploying to Kubernetes](#deploying-to-kubernetes)
* [Configuring the containers](#configuring-the-containers)
  * [SE_OPTS Selenium Configuration Options](#se_opts-selenium-configuration-options)
  * [SE_JAVA_OPTS Java Environment Options](#se_java_opts-java-environment-options)
  * [SE_BROWSER_ARGS_* Add arguments for launching browser](#se_browser_args_-add-arguments-for-launching-browser)
  * [Node configuration options](#node-configuration-options)
  * [Node configuration relay commands](#node-configuration-relay-commands)
  * [Setting Sub Path](#setting-sub-path)
  * [Setting Screen Resolution](#setting-screen-resolution)
  * [Grid Url and Session Timeout](#grid-url-and-session-timeout)
  * [Session request timeout](#session-request-timeout)
  * [Increasing session concurrency per container](#increasing-session-concurrency-per-container)
  * [Running in Headless mode](#running-in-headless-mode)
  * [Stopping the Node/Standalone after N sessions have been executed](#stopping-the-nodestandalone-after-n-sessions-have-been-executed)
  * [Automatic browser leftovers cleanup](#automatic-browser-leftovers-cleanup)
  * [Mask sensitive information in console logs](#mask-sensitive-information-in-console-logs)
  * [Secure Connection](#secure-connection)
  * [Browser language and locale](#browser-language-and-locale)
  * [Managing processes in container](#managing-processes-in-container)
* [Building the images](#building-the-images)
* [Build the images with specific versions](#build-the-images-with-specific-versions)
* [Upgrade browser version in the images](#upgrade-browser-version-in-the-images)
* [Waiting for the Grid to be ready](#waiting-for-the-grid-to-be-ready)
  * [Adding a HEALTHCHECK to the Grid](#adding-a-healthcheck-to-the-grid)
  * [Using a bash script to wait for the Grid](#using-a-bash-script-to-wait-for-the-grid)
* [Install certificates for Chromium-based browsers](#install-certificates-for-chromium-based-browsers)
* [Alternative method: Add certificates to existing Selenium based images for browsers](#alternative-method-add-certificates-to-existing-selenium-based-images-for-browsers)
* [Debugging](#debugging)
  * [Using a VNC client](#using-a-vnc-client)
  * [Using your browser (no VNC client is needed)](#using-your-browser-no-vnc-client-is-needed)
  * [Disabling VNC](#disabling-vnc)
* [Tracing in Grid](#tracing-in-grid)
* [Troubleshooting](#troubleshooting)
  * [`--shm-size="2g"`](#--shm-size2g)
  * [Headless](#headless)
  * [Mounting volumes to retrieve downloaded files](#mounting-volumes-to-retrieve-downloaded-files)
  * [Mounting volumes to retrieve video files](#mounting-volumes-to-retrieve-video-files)
* [Stargazers over time](#stargazers-over-time)
<!-- TOC -->

## Quick start

1. Start a Docker container with Firefox

```bash
docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-firefox:4.33.0-20250606
```

2. Point your WebDriver tests to http://localhost:4444

3. That's it! 

4. (Optional) To see what is happening inside the container, head to <http://localhost:7900/?autoconnect=1&resize=scale&password=secret>.

For more details about visualising the container activity, check the [Debugging](#debugging) section.

:point_up: When executing `docker run` for an image that contains a browser please use 
the flag `--shm-size=2g` to use the host's shared memory.
  
:point_up: Always use a Docker image with a full tag to pin a specific browser and Grid version.
See [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

### Try them out in a ready-to-use GitPod environment!

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/SeleniumHQ/docker-selenium)

___

## Experimental Multi-Arch amd64/aarch64/armhf Images

From image tag based `4.21.0` onwards, the architectures supported by this project are as below:

|       Architecture        | Available |
|:-------------------------:|:---------:|
|    x86_64 (aka amd64)     |     ✅     |
| aarch64 (aka arm64/armv8) |     ✅     |
| armhf (aka arm32/armv7l)  |     ❌     |

### Browser images in multi-arch

The following browsers are available in multi-arch images:

|       Architecture        | Chrome | Chromium | Firefox | Edge  |
| :-----------------------: | :----: | :------: | :-----: | :---: |
|    x86_64 (aka amd64)     |   ✅    |    ✅     |    ✅    |   ✅   |
| aarch64 (aka arm64/armv8) |   ❌    |    ✅     |    ✅    |   ❌   |
| armhf (aka arm32/armv7l)  |   ❌    |    ❌     |    ❌    |   ❌   |

Note:

- Google does not build Chrome (`google-chrome`) for Linux/ARM platforms. Hence, the Chrome (node and standalone) images are only available for AMD64.
Similarly, Microsoft does not build Edge (`microsoft-edge`) for Linux/ARM platforms.

- Running an AMD64 image under emulation on an ARM64 platform is not recommended due to performance and [stability issues](https://github.com/SeleniumHQ/docker-selenium/issues/2298).

- For Linux/ARM use the open source Chromium browser. The Chromium (node and standalone) images are available in multi-arch.

```bash
$ docker run --rm -it -p 4444:4444 -p 5900:5900 -p 7900:7900 --shm-size 2g selenium/standalone-chromium:latest
```

- Mozilla Firefox now is available for Linux/ARM64 via APT stable channel from v136+. The Firefox (node and standalone) images are available in multi-arch.

Multi-arch images are tested on CircleCI with resource class Linux/ARM64. See the status below.

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/SeleniumHQ/docker-selenium/tree/trunk.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/SeleniumHQ/docker-selenium/tree/trunk)

### History of the multi-arch images

For experimental docker container images, which run on platforms such as the Apple M-series or Raspberry Pi,
the repository at
[seleniumhq-community/docker-seleniarm](https://github.com/seleniumhq-community/docker-seleniarm) provided images which
are published on the [Seleniarm Docker Hub](https://hub.docker.com/u/seleniarm) registry.

See issue [#1076](https://github.com/SeleniumHQ/docker-selenium/issues/1076) for more information on these images.

Now, the fork [seleniumhq-community/docker-seleniarm](https://github.com/seleniumhq-community/docker-seleniarm) was merged.

### Build the multi-arch images locally

We recommend to enable the experimental feature [containerd image store](https://docs.docker.com/storage/containerd/) in Docker Engine.
`containerd` understands multiplatform images, where a single image tag can refer to different variants covering a range of OS and hardware architectures.
It simplifies the process of building, storing, and distributing images across different platforms.

A single command to enable that feature in Docker Engine:

```bash
make set_containerd_image_store
```

To build all the images for multiplatform at once, run the following command:

```bash
PLATFORMS=linux/amd64,linux/arm64 make build
```

To build the images for a specific platform, run the following command:

```bash
PLATFORMS=linux/arm64 make build
```

By default, without specifying the `PLATFORMS` variable, the images are built with current host architecture.

Similarly, if you are using host ARM64 architecture, you can build the images for AMD64 architecture by running the following command:

```bash
PLATFORMS=linux/amd64 make build
```

___

## Nightly Images

Nightly images are built on top of the [Nightly](https://github.com/SeleniumHQ/selenium/releases/tag/nightly) build on the upstream project [Selenium](https://github.com/SeleniumHQ/selenium) with the latest changes on main branch in this repository. The image tag is `nightly`. This is not recommended to use images in production. It is only for testing purpose.

```bash
$ docker run -d -p 4442-4444:4442-4444 --name selenium-hub selenium/hub:nightly
```

Check out the docker compose to get started with Nightly images [docker-compose-v3-full-grid-nightly.yml](docker-compose-v3-full-grid-nightly.yml)

## Dev and Beta Channel Browser Images

To run tests or otherwise work with pre-release browsers, Google, Mozilla, and Microsoft maintain a Dev and Beta release channel for those who need to see what's soon to be released to the general population.  

### Dev and Beta Standalone Mode

Here are the instructions to run them in Standalone mode:

**Chrome Beta:**

```bash
$ docker run --rm -it -p 4444:4444 -p 7900:7900 --shm-size 2g selenium/standalone-chrome:beta
```

**Chrome Dev:**

```bash
$ docker run --rm -it -p 4444:4444 -p 7900:7900 --shm-size 2g selenium/standalone-chrome:dev
```

**Firefox Beta:**

```bash
$ docker run --rm -it -p 4444:4444 -p 7900:7900 --shm-size 2g selenium/standalone-firefox:beta
```

**Firefox Dev:**

```bash
$ docker run --rm -it -p 4444:4444 -p 7900:7900 --shm-size 2g selenium/standalone-firefox:dev
```

**Edge Beta:**

```bash
$ docker run --rm -it -p 4444:4444 -p 7900:7900 --shm-size 2g selenium/standalone-edge:beta
```

**Edge Dev:**

```bash
$ docker run --rm -it -p 4444:4444 -p 7900:7900 --shm-size 2g selenium/standalone-edge:dev
```

### Dev and Beta on the Grid

**docker-compose-v3-beta-channel.yml:**
```bash
# To execute this docker compose yml file use `docker compose -f docker-compose-v3-beta-channel.yml up`
# Add the `-d` flag at the end for detached execution
# To stop the execution, hit Ctrl+C, and then `docker compose -f docker-compose-v3-beta-channel.yml down`
services:
  chrome:
    image: selenium/node-chrome:beta
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub

  edge:
    image: selenium/node-edge:beta
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub

  firefox:
    image: selenium/node-firefox:beta
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub

  selenium-hub:
    image: selenium/hub:latest
    container_name: selenium-hub
    ports:
      - "4442:4442"
      - "4443:4443"
      - "4444:4444"
```

**docker-compose-v3-dev-channel.yml:**
```bash
# To execute this docker compose yml file use `docker compose -f docker-compose-v3-dev-channel.yml up`
# Add the `-d` flag at the end for detached execution
# To stop the execution, hit Ctrl+C, and then `docker compose -f docker-compose-v3-dev-channel.yml down`
services:
  chrome:
    image: selenium/node-chrome:dev
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub

  edge:
    image: selenium/node-edge:dev
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub

  firefox:
    image: selenium/node-firefox:dev
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub

  selenium-hub:
    image: selenium/hub:latest
    container_name: selenium-hub
    ports:
      - "4442:4442"
      - "4443:4443"
      - "4444:4444"
```

For more information on the Dev and Beta channel container images, see the blog post on [Dev and Beta Channel Browsers via Docker Selenium](https://www.selenium.dev/blog/2022/dev-and-beta-channel-browsers-via-docker-selenium/).

## Environment Variables

**Checkout full list of environment variables [here](ENV_VARIABLES.md).**

How to update or contribute to list of environment variables? Follow below steps:

1. Refresh the list to pick up new environment variables or default value

    ```bash
    make update_list_env_vars
    ```

    The script can be updated in [scripts/generate_list_env_vars/extract_env.py](scripts/generate_list_env_vars/extract_env.py).

2. Update the description for each environment variable in the file [scripts/generate_list_env_vars/description.yaml](scripts/generate_list_env_vars/description.yaml).

3. Run the command in step (1) one more time to update the list of environment variables with new descriptions.

## Execution modes

### Standalone

![Firefox](https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_24x24.png) Firefox 
```bash
docker run -d -p 4444:4444 --shm-size="2g" selenium/standalone-firefox:4.33.0-20250606
```

![Chrome](https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_24x24.png) Chrome 
```bash
docker run -d -p 4444:4444 --shm-size="2g" selenium/standalone-chrome:4.33.0-20250606
```

![Edge](https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_24x24.png) Edge
```bash
docker run -d -p 4444:4444 --shm-size="2g" selenium/standalone-edge:4.33.0-20250606
```

_Note: Only one Standalone container can run on port_ `4444` _at the same time._

___

### Hub and Nodes

There are different ways to run the images and create a Grid with a Hub and Nodes, check the following options.

#### Docker networking
The Hub and Nodes will be created in the same network and they will recognize each other by their container name.
A Docker [network](https://docs.docker.com/engine/reference/commandline/network_create/) needs to be created as a first step.

##### macOS/Linux

```bash
$ docker network create grid
$ docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
    selenium/node-chrome:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
    selenium/node-edge:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
    selenium/node-firefox:4.33.0-20250606
```

##### Windows PowerShell

```powershell
$ docker network create grid
$ docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub `
    --shm-size="2g" `
    selenium/node-chrome:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub `
    --shm-size="2g" `
    selenium/node-edge:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub `
    --shm-size="2g" `
    selenium/node-firefox:4.33.0-20250606
```

When you are done using the Grid, and the containers have exited, the network can be removed with the following command:

``` bash
# Removes the grid network
$ docker network rm grid
```

#### Using different machines/VMs
The Hub and Nodes will be created on different machines/VMs, they need to know each other's IPs to
communicate properly. If more than one node will be running on the same Machine/VM, they must be
configured to expose different ports.

##### Hub - Machine/VM 1
```bash
$ docker run -d -p 4442-4444:4442-4444 --name selenium-hub selenium/hub:4.33.0-20250606
```

##### Node Chrome - Machine/VM 2

###### macOS/Linux

```bash
$ docker run -d -p 5555:5555 \
    --shm-size="2g" \
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> \
    -e SE_NODE_HOST=<ip-from-machine-2> \
    selenium/node-chrome:4.33.0-20250606
```

###### Windows PowerShell

```powershell
$ docker run -d -p 5555:5555 `
    --shm-size="2g" `
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> `
    -e SE_NODE_HOST=<ip-from-machine-2> `
    selenium/node-chrome:4.33.0-20250606
```


##### Node Edge - Machine/VM 3

###### macOS/Linux

```bash
$ docker run -d -p 5555:5555 \
    --shm-size="2g" \
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> \
    -e SE_NODE_HOST=<ip-from-machine-3> \
    selenium/node-edge:4.33.0-20250606
```

###### Windows PowerShell

```powershell
$ docker run -d -p 5555:5555 `
    --shm-size="2g" `
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> `
    -e SE_NODE_HOST=<ip-from-machine-3> `
    selenium/node-edge:4.33.0-20250606
```

##### Node Firefox - Machine/VM 4

###### macOS/Linux

```bash
$ docker run -d -p 5555:5555 \
    --shm-size="2g" \
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> \
    -e SE_NODE_HOST=<ip-from-machine-4> \
    selenium/node-firefox:4.33.0-20250606
```

###### Windows PowerShell

```powershell
$ docker run -d -p 5555:5555 `
    --shm-size="2g" `
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> `
    -e SE_NODE_HOST=<ip-from-machine-4> `
    selenium/node-firefox:4.33.0-20250606
```

##### Node Chrome - Machine/VM 4

###### macOS/Linux

``` bash
$ docker run -d -p 5556:5556 \
    --shm-size="2g" \
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> \
    -e SE_NODE_HOST=<ip-from-machine-4> \
    -e SE_NODE_PORT=5556 \
    selenium/node-chrome:4.33.0-20250606
```

###### Windows PowerShell

```powershell
$ docker run -d -p 5556:5556 `
    --shm-size="2g" `
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> `
    -e SE_NODE_HOST=<ip-from-machine-4> `
    -e SE_NODE_PORT=5556 `
    selenium/node-chrome:4.33.0-20250606
```

#### Docker Compose
[Docker Compose](https://docs.docker.com/compose/) is the simplest way to start a Grid. Use the
linked resources below, save them locally and check the execution instructions on top of each file.

##### Version 2
[`docker-compose-v2.yml`](docker-compose-v2.yml)

##### Version 3
[`docker-compose-v3.yml`](docker-compose-v3.yml)

To stop the Grid and cleanup the created containers, run `docker compose down`.

##### Version 3 with Swarm support 
[`docker-compose-v3-swarm.yml`](docker-compose-v3-swarm.yml)

___

### Fully distributed mode - Router, Queue, Distributor, EventBus, SessionMap and Nodes

It is possible to start a Selenium Grid with all its components apart. For simplicity, only an
example with docker compose will be provided. Save the file locally, and check the execution 
instructions on top of it.

[`docker-compose-v3-full-grid.yml`](docker-compose-v3-full-grid.yml)

#### Distributor configuration

| Environment variable         | Option                      | Type    | Default value | Description                                                                                                  |
|------------------------------|-----------------------------|---------|---------------|--------------------------------------------------------------------------------------------------------------|
| `SE_REJECT_UNSUPPORTED_CAPS` | `--reject-unsupported-caps` | boolean | `false`       | Allow the Distributor to reject a request immediately if the Grid does not support the requested capability. |
| `SE_HEALTHCHECK_INTERVAL`    | `--healthcheck-interval`    | int     | `120`         | This ensures the server can ping all the Nodes successfully after an interval.                               |

___

## Video recording

Tests execution can be recorded by using the `selenium/video:ffmpeg-7.1-20250606`
Docker image. One container is needed per each container where a browser is running. This means if you are
running 5 Nodes/Standalone containers, you will need 5 video containers, the mapping is 1-1.

Currently, the only way to do this mapping is manually (either starting the containers manually or through
`docker compose`). We are iterating on this process and probably this setup will be more simple in the future.

The video Docker image we provide is based on the ffmpeg Ubuntu image provided by the 
[jrottenberg/ffmpeg](https://github.com/jrottenberg/ffmpeg) project, thank you for providing this image and
simplifying our work :tada:

From image tag based `4.20.0` onwards, the video Docker image is based on the FFmpeg Ubuntu image provided by
[linuxserver/docker-ffmpeg](https://github.com/linuxserver/docker-ffmpeg) project since the image is available for multi-platform.
Thank you for simplifying our project and helping us move forward with multiple architecture support.

**Notes**:
- If you have questions or feedback, please use the community contact points shown [here](https://www.selenium.dev/support/). 
- Please report any bugs through GitHub [issues](https://github.com/SeleniumHQ/docker-selenium/issues/new/choose), and provide
all the information requested on the template.
- Video recording for headless browsers is not supported. 
- Video recording tends to use considerable amounts of CPU. Normally you should estimate 1CPU per video container, 
and 1 CPU per browser container.
- Videos are stored in the `/videos` directory inside the video container. Map a local directory to get the videos.
- If you are running more than one video container, be sure to overwrite the video file name through the `FILE_NAME`
environment variable to avoid unexpected results.

This example shows how to start the containers manually:

``` bash
$ docker network create grid
$ docker run -d -p 4444:4444 -p 6900:5900 --net grid --name selenium --shm-size="2g" selenium/standalone-chrome:4.33.0-20250606
$ docker run -d --net grid --name video -v /tmp/videos:/videos selenium/video:ffmpeg-7.1-20250606
# Run your tests
$ docker stop video && docker rm video
$ docker stop selenium && docker rm selenium
```
After the containers are stopped and removed, you should see a video file on your machine's `/tmp/videos` directory.

Here is an example using a Hub and a few Nodes:

[`docker-compose-v3-video.yml`](docker-compose-v3-video.yml)

## Video recording with dynamic file name based on metadata in tests

Based on the support of [Metadata in tests](https://www.selenium.dev/documentation/grid/getting_started/#metadata-in-tests). When the video recorder is sidecar deployed with the browser node with enabling `SE_VIDEO_FILE_NAME=auto` and adding metadata to your tests, video file name will extract value of capability `se:name` and use it as the video file name.

For example in Python binding:

```python
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium import webdriver

options = ChromeOptions()
options.set_capability('se:name', 'test_visit_basic_auth_secured_page (ChromeTests)')
driver = webdriver.Remote(options=options, command_executor="http://localhost:4444")
driver.get("https://selenium.dev")
driver.quit()
```

The output video file name will be `test_visit_basic_auth_secured_page_ChromeTests_<sessionId>.mp4`.

If your test name is handled by the test framework, and it is unique for sure, you also can disable the session id appends to the video file name by setting `SE_VIDEO_FILE_NAME_SUFFIX=false`.

File name will be trimmed to 255 characters to avoid long file names. Moreover, `space` character will be replaced by `_` and only characters alphabets, numbers, `-` (hyphen), `_` (underscore) are retained in the file name.

The trim regex is able to be customized by setting `SE_VIDEO_FILE_NAME_TRIM_REGEX` environment variable. The default value is `[:alnum:]-_`. The regex should be compatible with the `tr` command in bash.

At deployment level, the recorder container is up always. In addition, you can disable video recording process via session capability `se:recordVideo`. For example in Python binding:

```python
options.set_capability('se:recordVideo', False)
```

In recorder container will perform query GraphQL in Hub based on Node SessionId and extract the value of `se:recordVideo` in capabilities before deciding to start video recording process or not.

Notes: To reach the GraphQL endpoint, the recorder container needs to know the Hub URL. The Hub URL can be passed via environment variable `SE_NODE_GRID_URL`. For example `SE_NODE_GRID_URL` is `http://selenium-hub:4444`.

## Video recording and uploading

[RCLONE](https://rclone.org/) is installed in the video recorder image. You can use it to upload the videos to a cloud storage service.
Besides the video recording mentioned above, you can enable the upload functionality by setting the following environment variables:

```yaml
services:
  chrome_video:
    image: selenium/video:ffmpeg-7.1-20250606
    depends_on:
      - chrome
    environment:
      - DISPLAY_CONTAINER_NAME=chrome
      - SE_VIDEO_FILE_NAME=auto
      - SE_VIDEO_UPLOAD_ENABLED=true
      - SE_UPLOAD_DESTINATION_PREFIX=s3://mybucket/path
      - RCLONE_CONFIG_S3_TYPE=s3
      - RCLONE_CONFIG_S3_PROVIDER=GCS
      - RCLONE_CONFIG_S3_ENV_AUTH=true
      - RCLONE_CONFIG_S3_REGION=asia-southeast1
      - RCLONE_CONFIG_S3_LOCATION_CONSTRAINT=asia-southeast1
      - RCLONE_CONFIG_S3_ACL=private
      - RCLONE_CONFIG_S3_ACCESS_KEY_ID=xxx
      - RCLONE_CONFIG_S3_SECRET_ACCESS_KEY=xxx
      - RCLONE_CONFIG_S3_ENDPOINT=https://storage.googleapis.com
      - RCLONE_CONFIG_S3_NO_CHECK_BUCKET=true
```

`SE_VIDEO_FILE_NAME=auto` will use the session id as the video file name. This ensures that the video file name is unique to upload.
Video file name construction automatically works based on Node endpoint `/status` (and optional GraphQL endpoint) to get session ID, capabilities.

`SE_VIDEO_UPLOAD_ENABLED=true` (`false` by default) will enable the video upload feature. In the background, it will create a pipefile with file and destination for uploader to consume and proceed.

`SE_VIDEO_INTERNAL_UPLOAD=true` (by default) will use RCLONE installed in the container for upload. If you want to use another sidecar container for upload, set it to `false`.

| ENV variables per mode                   | Hub/Nodes         | Standalone roles | Dynamic Grid   |
|------------------------------------------|-------------------|------------------|----------------|
| `SE_VIDEO_RECORD_STANDALONE` (mandatory) | `false` (default) | `true`           | `true`         |
| `DISPLAY_CONTAINER_NAME` (mandatory)     | user input        | user input       | (not required) |
| `SE_NODE_PORT` (optional)                | `5555`            | `4444`           | (not required) |
| `SE_NODE_GRID_URL` (optional)            | user input        | (not required)   | (not required) |

For environment variables with prefix `RCLONE_` is used to pass remote configuration to RCLONE. You can find more information about RCLONE configuration [here](https://rclone.org/docs/).
When using in Dynamic Grid, those variables should be combined with the prefix `SE_`, for example `SE_RCLONE_`. See below reference for more details.

### Reference
- Configure video recording and uploading for Hub and Nodes: [docker-compose-v3-video-upload.yml](docker-compose-v3-video-upload.yml)

- Configure video recording and uploading for Standalone roles: [docker-compose-v3-video-upload-standalone.yml](docker-compose-v3-video-upload-standalone.yml)

- Configure video recording and uploading for Dynamic Grid (node-docker): [docker-compose-v3-video-upload-dynamic-grid.yml](docker-compose-v3-video-upload-dynamic-grid.yml)

- Configure video recording and uploading for Dynamic Grid standalone (standalone-docker): [tests/docker-compose-v3-test-standalone-docker.yaml](tests/docker-compose-v3-test-standalone-docker.yaml)

### Environment variables and default values for upload feature

| Environment variable          | Default value                                | Description                                                                               |
|-------------------------------|----------------------------------------------|-------------------------------------------------------------------------------------------|
| `SE_UPLOAD_RETAIN_LOCAL_FILE` | `false`                                      | Keep local file after uploading successfully                                              |
| `SE_UPLOAD_COMMAND`           | `copy`                                       | RCLONE command is used to transfer file. Enforce `move` when retain local file is `false` |
| `SE_UPLOAD_OPTS`              | `-P --cutoff-mode SOFT --metadata --inplace` | Other options belong to RCLONE command can be set.                                        |
| `SE_UPLOAD_CONFIG_FILE_NAME`  | `upload.conf`                                | Config file for remote host instead of set via env variable prefix SE_RCLONE_*            |
| `SE_UPLOAD_CONFIG_DIRECTORY`  | `/opt/bin`                                   | Directory of config file (change it when conf file in another directory is mounted)       |

## Video recordings manager

We utilize [File Browser](https://filebrowser.org/) as a video manager. It is a web-based file manager that allows you to manage files and folders in the storage.

The File Browser container dir `/srv` should be mounted to the same storage as video recordings stored. For example a compose file:

```yaml
services:
  chrome:
    deploy:
      mode: replicated
      replicas: 3
    image: selenium/node-chrome:4.33.0-20250606
    platform: linux/amd64
    shm_size: 2gb
    depends_on:
      - selenium-hub
    volumes:
      - /tmp/videos:/videos
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_RECORD_VIDEO=true
      - SE_VIDEO_FILE_NAME=auto
      - SE_NODE_GRID_URL=http://selenium-hub:4444

  file_browser:
      image: filebrowser/filebrowser:latest
      container_name: file_browser
      restart: always
      ports:
          - "8081:80"
      volumes:
          - /tmp/videos:/srv
      environment:
          - FB_NOAUTH=true
```

___

## Dynamic Grid

Grid 4 has the ability to start Docker containers on demand, this means that it starts
a Docker container in the background for each new session request, the test gets executed
there, and when the test completes, the container gets thrown away.

This execution mode can be used either in the Standalone or Node roles. The "dynamic"
execution mode needs to be told what Docker images to use when the containers get started.
Additionally, the Grid needs to know the URI of the Docker daemon. This configuration can
be placed in a local `toml` file.

### Configuration example

You can save this file locally and name it, for example, `config.toml`.
```toml
[docker]
# Configs have a mapping between the Docker image to use and the capabilities that need to be matched to
# start a container with the given image.
configs = [
    "selenium/standalone-firefox:4.33.0-20250606", '{"browserName": "firefox"}',
    "selenium/standalone-chrome:4.33.0-20250606", '{"browserName": "chrome"}',
    "selenium/standalone-edge:4.33.0-20250606", '{"browserName": "MicrosoftEdge"}'
]

host-config-keys = ["Dns", "DnsOptions", "DnsSearch", "ExtraHosts", "Binds"]

# URL for connecting to the docker daemon
# Most simple approach, leave it as http://127.0.0.1:2375, and mount /var/run/docker.sock.
# 127.0.0.1 is used because internally the container uses socat when /var/run/docker.sock is mounted 
# If var/run/docker.sock is not mounted: 
# Windows: make sure Docker Desktop exposes the daemon via tcp, and use http://host.docker.internal:2375.
# macOS: install socat and run the following command, socat -4 TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock,
# then use http://host.docker.internal:2375.
# Linux: varies from machine to machine, please mount /var/run/docker.sock. If this does not work, please create an issue.
url = "http://127.0.0.1:2375"
# Docker image used for video recording
video-image = "selenium/video:ffmpeg-7.1-20250606"

# Uncomment the following section if you are running the node on a separate VM
# Fill out the placeholders with appropriate values
#[server]
#host = <ip-from-node-machine>
#port = <port-from-node-machine>
```

**Mount the local `config.toml` file to the container path `/opt/selenium/docker.toml`**.
This config file path specific for Dynamic Grid (node/standalone docker) by default to avoid conflict with the config file in node browser containers (since users can share volumes config to node browser containers, see below section for details).

With the optional config key `host-config-keys` under section [docker] in a config.toml file (or CLI option --docker-host-config-keys). Users can specify a list of docker host configuration keys that should be passed to browser containers.

Valid key names for Docker host config can be found in the Docker API [documentation](https://docs.docker.com/engine/api/latest/#tag/Container/operation/ContainerCreate) or via the command `docker inspect` the node-docker container.

### Share volumes config of Dynamic Grid container to node browser containers

In case you want to access download directory in node browser containers (e.g `/home/seluser/Downloads`) via volumes config of Dynamic Grid container, you can add the following config to the `config.toml` file

```toml
[docker]
host-config-keys = ["Binds"]
```

Volumes config in docker compose file

```yaml
services:
  node-docker:
    image: selenium/node-docker:latest
    volumes:
      - ./assets:/opt/selenium/assets
      - ./config.toml:/opt/selenium/docker.toml
      - ./downloads:/home/seluser/Downloads
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - SE_NODE_DOCKER_CONFIG_FILENAME=docker.toml
```

`/opt/selenium/config.toml` is the default path for the config file in all images. Once volumes config is shared to node browser containers, its `config.toml` could be overwritten by node-docker container config file.

In this case, mount your `config.toml` file to `/opt/selenium/docker.toml` in node-docker container. And set the environment variable `SE_NODE_DOCKER_CONFIG_FILENAME=docker.toml` to specify that config file name for the startup script.

Refer to example [docker-compose-v3-test-node-docker.yaml](./tests/docker-compose-v3-test-node-docker.yaml)

### Execution with Hub & Node roles

This can be expanded to a full Grid deployment, all components deployed individually. The overall
idea is to have the Hub in one virtual machine, and each of the Nodes in separate and more powerful
virtual machines. 

#### macOS/Linux

```bash
$ docker network create grid
$ docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    -v ${PWD}/config.toml:/opt/selenium/docker.toml \
    -v ${PWD}/assets:/opt/selenium/assets \
    -v /var/run/docker.sock:/var/run/docker.sock \
    selenium/node-docker:4.33.0-20250606
```

#### Windows PowerShell

```powershell
$ docker network create grid
$ docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub `
    -v ${PWD}/config.toml:/opt/selenium/docker.toml `
    -v ${PWD}/assets:/opt/selenium/assets `
    -v /var/run/docker.sock:/var/run/docker.sock `
    selenium/node-docker:4.33.0-20250606
```

To have the assets saved on your host, please mount your host path to `/opt/selenium/assets`.

When you are done using the Grid, and the containers have exited, the network can be removed with the following command:

``` bash
# Removes the grid network
$ docker network rm grid
```

### Execution with Standalone roles

#### macOS/Linux

```bash
docker run --rm --name selenium-docker -p 4444:4444 \
    -v ${PWD}/config.toml:/opt/selenium/docker.toml \
    -v ${PWD}/assets:/opt/selenium/assets \
    -v /var/run/docker.sock:/var/run/docker.sock \
    selenium/standalone-docker:4.33.0-20250606
```

#### Windows PowerShell

```bash
docker run --rm --name selenium-docker -p 4444:4444 `
    -v ${PWD}/config.toml:/opt/selenium/docker.toml `
    -v ${PWD}/assets:/opt/selenium/assets `
    -v /var/run/docker.sock:/var/run/docker.sock `
    selenium/standalone-docker:4.33.0-20250606
```

### Using Dynamic Grid in different machines/VMs

#### Hub - Machine/VM 1

```bash
$ docker run -d -p 4442-4444:4442-4444 --name selenium-hub selenium/hub:4.33.0-20250606
```

#### Node Chrome - Machine/VM 2

#### macOS/Linux

```bash
$ docker run -d -p 5555:5555 \
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> \
    -v ${PWD}/config.toml:/opt/selenium/docker.toml \
    -v ${PWD}/assets:/opt/selenium/assets \
    -v /var/run/docker.sock:/var/run/docker.sock \
    selenium/node-docker:4.33.0-20250606
```

#### Windows PowerShell

```bash
$ docker run -d -p 5555:5555 `
    -e SE_EVENT_BUS_HOST=<ip-from-machine-1> `
    -v ${PWD}/config.toml:/opt/selenium/docker.toml `
    -v ${PWD}/assets:/opt/selenium/assets `
    -v /var/run/docker.sock:/var/run/docker.sock `
    selenium/node-docker:4.33.0-20250606
```

Complete the `[server]` section in the `config.toml` file.
```toml
[docker]
# Configs have a mapping between the Docker image to use and the capabilities that need to be matched to
# start a container with the given image.
configs = [
    "selenium/standalone-firefox:4.33.0-20250606", "{\"browserName\": \"firefox\"}",
    "selenium/standalone-chrome:4.33.0-20250606", "{\"browserName\": \"chrome\"}",
    "selenium/standalone-edge:4.33.0-20250606", "{\"browserName\": \"MicrosoftEdge\"}"
    ]

# URL for connecting to the docker daemon
# Most simple approach, leave it as http://127.0.0.1:2375, and mount /var/run/docker.sock.
# 127.0.0.1 is used because interally the container uses socat when /var/run/docker.sock is mounted 
# If var/run/docker.sock is not mounted: 
# Windows: make sure Docker Desktop exposes the daemon via tcp, and use http://host.docker.internal:2375.
# macOS: install socat and run the following command, socat -4 TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock,
# then use http://host.docker.internal:2375.
# Linux: varies from machine to machine, please mount /var/run/docker.sock. If this does not work, please create an issue.
url = "http://127.0.0.1:2375"
# Docker image used for video recording
video-image = "selenium/video:ffmpeg-7.1-20250606"

# Uncomment the following section if you are running the node on a separate VM
# Fill out the placeholders with appropriate values
[server]
host = <ip-from-node-machine>
port = <port-from-node-machine>
```

To have the assets saved on your host, please mount your host path to `/opt/selenium/assets`.

### Execution with Docker Compose

Here is an example using a Hub and a Node:

[`docker-compose-v3-dynamic-grid.yml`](docker-compose-v3-dynamic-grid.yml)


### Configuring the child containers

Containers can be further configured through environment variables, such as `SE_NODE_SESSION_TIMEOUT`
and `SE_OPTS`. When a child container is created, all environment variables prefixed with `SE_` will
be forwared and set in the container. You can set the desired environment variables in the 
`standalone-docker` or `node-docker` containers. The following example sets the session timeout to
700 seconds for all sessions:

#### macOS/Linux

```bash
docker run --rm --name selenium-docker -p 4444:4444 \
    -e SE_NODE_SESSION_TIMEOUT=700 \
    -v ${PWD}/config.toml:/opt/selenium/docker.toml \
    -v ${PWD}/assets:/opt/selenium/assets \
    -v /var/run/docker.sock:/var/run/docker.sock \
    selenium/standalone-docker:4.33.0-20250606
```

#### Windows PowerShell

```bash
docker run --rm --name selenium-docker -p 4444:4444 `
    -e SE_NODE_SESSION_TIMEOUT=700 `
    -v ${PWD}/config.toml:/opt/selenium/docker.toml `
    -v ${PWD}/assets:/opt/selenium/assets `
    -v /var/run/docker.sock:/var/run/docker.sock `
    selenium/standalone-docker:4.33.0-20250606
```

### Video recording, screen resolution, and time zones in a Dynamic Grid
To record your WebDriver session, you need to add a `se:recordVideo` 
field set to `true`. You can also set a time zone and a screen resolution,
for example:

```json
{
  "browserName": "firefox",
  "platformName": "linux",
  "se:recordVideo": "true",
  "se:timeZone": "US/Pacific",
  "se:screenResolution": "1920x1080"  
}
```

After running a test, check the path you mounted to the Docker container, 
(`${PWD}/assets`), and you should see videos and session information. 

From language bindings, you can set the `se:name` capability to change output video file name dynamically. For example, in Python binding:

```python
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium import webdriver

options = ChromeOptions()
options.set_capability('se:recordVideo', True)
options.set_capability('se:screenResolution', '1920x1080')
options.set_capability('se:name', 'test_visit_basic_auth_secured_page (ChromeTests)')
driver = webdriver.Remote(options=options, command_executor="http://localhost:4444")
driver.get("https://selenium.dev")
driver.quit()
```

After test executed, under (`${PWD}/assets`) you can see the video file name in path `/<sessionId>/test_visit_basic_auth_secured_page_ChromeTests.mp4`

The file name will be trimmed to 255 characters to avoid long file names. Moreover, the `space` character will be replaced by `_`, and only the characters alphabets, numbers, `-` (hyphen), and `_` (underscore) are retained in the file name. (This feat is available once this [PR](https://github.com/SeleniumHQ/selenium/pull/13907) merged)

### Time zone configuration via env variable

`tzdata` is installed in based images, and you can set the time zone in container by using the env variable `TZ`.
By default, the time zone is set to `UTC`.
List of supported time zones can be found [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). For example:

```bash
$ docker run --rm --entrypoint="" -e TZ=Asia/Ho_Chi_Minh selenium/node-chromium:latest date +%FT%T%Z
2024-08-28T18:19:26+07
```

___

## Deploying to Kubernetes

Get started to deploy Selenium Grid on Kubernetes, you can refer to YAML files in the [kubernetes](./kubernetes) directory.

To simplify the deployment process, hide the complexity of Kubernetes objects, and provide a more straightforward way to deploy Selenium Grid on Kubernetes, we offer a Helm chart to deploy Selenium Grid to Kubernetes.
Read more details at the Helm [chart README](./charts/selenium-grid/README.md) and [chart CONFIGURATION](./charts/selenium-grid/CONFIGURATION.md).

- Get started to hands-on with Selenium Grid on Kubernetes. See local env setup with [Docker Desktop](./tests/charts/refValues/README.md).

___

## Configuring the containers

### SE_OPTS Selenium Configuration Options

You can pass `SE_OPTS` variable with additional command line parameters for starting a hub or a node.

``` bash
$ docker run -d -p 4444:4444 -e SE_OPTS="--log-level FINE" --name selenium-hub selenium/hub:4.33.0-20250606
```

### SE_JAVA_OPTS Java Environment Options

You can pass `SE_JAVA_OPTS` environment variable to the Java process.

``` bash
$ docker run -d -p 4444:4444 -e SE_JAVA_OPTS=-Xmx512m --name selenium-hub selenium/hub:4.33.0-20250606
```

### SE_BROWSER_ARGS_* Add arguments for launching browser

Instead of adding arguments via the browser options from language bindings, for example:

```python
options = ChromeOptions()
options.add_argument('--incognito')
options.add_argument('--disable-dev-shm-usage')
driver = webdriver.Remote(options=options, command_executor="http://localhost:4444/wd/hub")
```

You also can proactive to force applying arguments directly from (node, standalone or node-docker) container environment variables. Define the environment variable with name starts with `SE_BROWSER_ARGS_` and following by config key is up to you (ensure those are unique when you define multiple arguments). For example:

```bash
docker run -d -p 4444:4444 \
  -e SE_BROWSER_ARGS_INCOGNITO=--incognito \
  -e SE_BROWSER_ARGS_DISABLE_DSHM=--disable-dev-shm-usage \
  selenium/standalone-chrome:latest
```

[List chromium command-line arguments](https://peter.sh/experiments/chromium-command-line-switches/) for your reference.

Note: Currently, this is applicable for node browsers Chrome/Chromium, Edge.

### Node configuration options

The Nodes register themselves through the Event Bus. When the Grid is started in its typical Hub/Node
setup, the Hub will be the one acting as the Event Bus, and when the Grid is started with all its five
elements apart, the Event Bus will be running on its own.

In both cases, it is necessary to tell the Node where the Event Bus is, so it can register itself. That is
the purpose of the `SE_EVENT_BUS_HOST`, `SE_EVENT_BUS_PUBLISH_PORT` and `SE_EVENT_BUS_SUBSCRIBE_PORT` environment
variables.

In some cases, for example, if you want to tag a node, it might be necessary to supply a custom stereotype to the node config. The environment variable `SE_NODE_STEREOTYPE`
sets the stereotype entry in the node's `config.toml`. An example config.toml file can be found here: [Setting custom capabilities for matching specific Nodes](https://www.selenium.dev/documentation/grid/configuration/toml_options/#setting-custom-capabilities-for-matching-specific-nodes).

Here is an example with the default values of these environment variables:
```bash
$ docker run -d \
  -e SE_EVENT_BUS_HOST=<event_bus_ip|event_bus_name> \
  -e SE_NODE_STEREOTYPE="{\"browserName\":\"${SE_NODE_BROWSER_NAME}\", \"browserVersion\":\"${SE_NODE_BROWSER_VERSION}\", \"platformName\":\"${SE_NODE_PLATFORM_NAME}\"}" \
  --shm-size="2g" selenium/node-chrome:4.33.0-20250606
```

In another case, if you want to retain the default Node stereotype and append additional capabilities, you can use the `SE_NODE_STEREOTYPE_EXTRA` environment variable to set your capabilities. Those will be merged to the default stereotype. For example:
```bash
$ docker run -d \
  -e SE_EVENT_BUS_HOST=<event_bus_ip|event_bus_name> \
  -e SE_NODE_STEREOTYPE_EXTRA="{\"myApp:version\":\"beta\", \"myApp:publish:\":\"public\"}" \
  --shm-size="2g" selenium/node-chrome:4.33.0-20250606
```

This help setting custom capabilities for matching specific Nodes. For example, you added your custom capabilities when starting the Node, and you want assign a test to run on that Node which matches your capabilities. For example in test code:

```python
options = ChromeOptions()
options.set_capability('myApp:version', 'beta')
options.set_capability('myApp:publish', 'public')
driver = webdriver.Remote(options=options, command_executor=SELENIUM_GRID_URL)
```

Noted: Your custom capabilities with key values should be in W3C capabilities convention, extension capabilities key must contain a ":" (colon) character, denoting an implementation specific namespace.

Noted: Ensure that Node config `detect-drivers = false` in `config.toml` (or `--detect-drivers false` in CLI option) to make feature setting custom capabilities for matching specific Nodes get working.

In addition, default Node stereotype includes capability `se:containerName` which can visible in node capabilities, or session capabilities to identify the container name where the node/session is running. **The prefixed `se:containerName` is not included in slot matcher**. By default, value is getting from `hostname` command in container, this value is equivalent to the `container_id` that you saw via `docker ps` command. If you want to override this value, you can set the environment variable `SE_NODE_CONTAINER_NAME` to your desired value. For example, when deploy to Kubernetes cluster, you can assign Pod name to env var `SE_NODE_CONTAINER_NAME` to track a node is running in which Pod.

```yaml
  env:
    - name: SE_NODE_CONTAINER_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
```

In an advanced case, where you control to spawn up a Node container, let it register to Hub, and then trigger a test to be assigned exactly to run on that Node. By default, the value of command `$(hostname)` is added to capability name `container:hostname` in Node stereotype. Combine with above feature setting custom capabilities for matching specific Nodes. You can use the `hostname` of the Node container just spawned up and set it as a custom capability. For example, in Python binding:

```bash
$ docker run -d --name my-node-1 -e SE_EVENT_BUS_HOST=localhost \
  --shm-size="2g" selenium/node-chrome:4.33.0-20250606
$ docker exec -i my-node-1 hostname
a6971f95bbab
```

```python
options = ChromeOptions()
options.set_capability('container:hostname', 'a6971f95bbab')
driver = webdriver.Remote(options=options, command_executor=SELENIUM_GRID_URL)
```

_Noted: Those above changes require new image tag where the changeset is included & released._

### Node configuration relay commands

Relaying commands to a service endpoint that supports WebDriver.
It is useful to connect an external service that supports WebDriver to Selenium Grid. An example of such service could be a cloud provider or an Appium server. 
In this way, Grid can enable more coverage to platforms and versions not present locally.

The following is an en example of configuration relay commands.

[docker-compose-v3-test-node-relay.yml](tests/docker-compose-v3-test-node-relay.yml)

If you want to relay commands only, `selenium/node-base` is suitable and lightweight for this purpose.
In case you want to configure node with both browsers and relay commands, respective node images can be used.

To use environment variables for generate relay configs, set `SE_NODE_RELAY_URL` and other variables as below. Those will be used to generate the default relay config in TOML format looks like below.

```toml
[relay]
url = "${SE_NODE_RELAY_URL}"
status-endpoint = "${SE_NODE_RELAY_STATUS_ENDPOINT}"
protocol-version = "${SE_NODE_RELAY_PROTOCOL_VERSION}"
configs = [ '${SE_NODE_RELAY_MAX_SESSIONS}', '{"browserName": "${SE_NODE_RELAY_BROWSER_NAME}", "platformName": "${SE_NODE_RELAY_PLATFORM_NAME}", "appium:platformVersion": "${SE_NODE_RELAY_PLATFORM_VERSION}"}' ]
```

Instead of input value for each environment variable to construct the default relay stereotype, you can use the `SE_NODE_RELAY_STEREOTYPE` environment variable to overwrite the default relay stereotype with your custom stereotype.

In another case, if you want to retain the default relay stereotype and append additional capabilities, you can use the `SE_NODE_RELAY_STEREOTYPE_EXTRA` environment variable to set your capabilities. Those will be merged to the default relay stereotype.

To run a sample test with the relayed node, you can clone the project and try below command:

```bash
make test_node_relay
```

### Setting Sub Path

By default, Selenium is reachable at `http://127.0.0.1:4444/`. Selenium can be configured to use a custom subpath by specifying the `SE_SUB_PATH`
environmental variable. In the example below Selenium is reachable at `http://127.0.0.1:4444/selenium-grid/`

```bash
$ docker run -d -p 4444:4444 -e SE_SUB_PATH=/selenium-grid/ --name selenium-hub selenium/hub:4.33.0-20250606
```

### Setting Screen Resolution

By default, nodes start with a screen resolution of 1920 x 1080 with a color depth of 24 bits and a dpi of 96. 
These settings can be adjusted by specifying `SE_SCREEN_WIDTH`, `SE_SCREEN_HEIGHT`, `SE_SCREEN_DEPTH`, and/or `SE_SCREEN_DPI` 
environmental variables when starting the container.

``` bash
docker run -d -e SE_SCREEN_WIDTH=1366 -e SE_SCREEN_HEIGHT=768 -e SE_SCREEN_DEPTH=24 -e SE_SCREEN_DPI=74 selenium/standalone-firefox:4.33.0-20250606
```

### Grid Url and Session Timeout

In some use cases, you might need to set the Grid URL to the Node, for example, if you'd like to access the BiDi/CDP endpoint. 
This is also needed when you want to use the new `RemoteWebDriver.builder()` or `Augmenter()` present in Selenium 4 
(since they setup the BiDi/CDP connection implicitly). You can do that through the `SE_NODE_GRID_URL` environment 
variable, eg `-e SE_NODE_GRID_URL=http://<hostMachine>:4444`. Setting this env var is needed if you want to see the live view while sessions are executing.

Grid has a default session timeout of 300 seconds, where the session can be in a stale state until it is killed. You can use
`SE_NODE_SESSION_TIMEOUT` to overwrite that value in seconds.


### Session request timeout

A new session request is placed in the Session Queue before it is processed, and the request sits in the queue until a matching
slot is found across the registered Nodes. However, the new session request might timeout if no slot was found. By default, a 
request will stay in the queue for up to 300 seconds before it a timeout is reached. In addition, an attempt to process the request
is done every 5 seconds (by default).

It is possible to override those values through environment variables in the Hub and the SessionQueue (`SE_SESSION_REQUEST_TIMEOUT`
and `SE_SESSION_RETRY_INTERVAL`). For example, a timeout of 500 seconds would be `SE_SESSION_REQUEST_TIMEOUT=500` and a retry 
interval of 2 seconds would be `SE_SESSION_RETRY_INTERVAL=2`.

### Increasing session concurrency per container

By default, only one session is configured to run per container through the `SE_NODE_MAX_SESSIONS` environment variable. It is
possible to increase that number up to the maximum available processors, this is because more stability is achieved when one
container/browser has 1 CPU to run. 

However, if you have measured performance and based on that, you think more sessions can be executed in each container, you can
override the maximum limit by setting both `SE_NODE_MAX_SESSIONS` to a desired number and `SE_NODE_OVERRIDE_MAX_SESSIONS` to 
`true`. Nevertheless, running more browser sessions than the available processors is not recommended since you will be overloading
the resources.

Overriding this setting has an undesired side effect when video recording is enabled since more than one browser session might be
captured in the same video.

### Running in Headless mode

[Firefox](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Headless_mode),
[Chrome](https://developer.chrome.com/docs/chromium/headless),
When using headless mode, there's no need for the [Xvfb](https://en.wikipedia.org/wiki/Xvfb) server to be started.

To avoid starting the server you can set the `SE_START_XVFB` environment variable to `false` 
(or any other value than `true`), for example:

``` bash
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
  -e SE_START_XVFB=false --shm-size="2g" selenium/node-chrome:4.33.0-20250606
```

For more information, see this GitHub [issue](https://github.com/SeleniumHQ/docker-selenium/issues/567).

Noted:
- In new Chrome/Chromium versions (v127+), `SE_START_XVFB` is required to be set to `true` to run in `--headless=new` mode.
- In new Chrome/Chromium versions (v132+), `--headless` only runs in the [`new` mode](https://developer.chrome.com/blog/removing-headless-old-from-chrome), so you need to set `SE_START_XVFB` to `true` when using `--headless` mode.

### Stopping the Node/Standalone after N sessions have been executed

In some environments, like Docker Swarm or Kubernetes, it is useful to shut down the Node or Standalone
container after N tests have been executed. For example, this can be used in Kubernetes to terminate the
pod and then scale a new one after N sessions. Set the environment variable `SE_DRAIN_AFTER_SESSION_COUNT` to
a value higher than zero to enable this behaviour. 

``` bash
$ docker run -e SE_DRAIN_AFTER_SESSION_COUNT=5 --shm-size="2g" selenium/standalone-firefox:4.33.0-20250606
```

With the previous command, the Standalone container will shut down after 5 sessions have been executed.

### Automatic browser leftovers cleanup

In long-running containers, it can happen that browsers leave some leftovers. These can be stuck browser processes
of jobs that have already finished but failed to fully stop the browser, or temporary files written to the `/tmp`
file system (notably on Chrome-based browsers). To avoid these filling up resources like process IDs and file system
usage in the container, there is an automatic cleanup script running every hour in the node containers. This will
clean up old processes and old temporary files. By default, this is disabled. When enabled, this will clean up browsers
running for longer than 2 hours, and files older than 1 day. These can be enabled and tweaked with the following
environment variables:

* `SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP`: default value `false`, set to `true` to enable the cleanup.
* `SE_BROWSER_LEFTOVERS_INTERVAL_SECS`: default value `3600` (1 hour), cleanup interval in seconds.
* `SE_BROWSER_LEFTOVERS_PROCESSES_SECS`: default value `7200` (2 hours), browsers running for longer than this time will be killed.
* `SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS`: default value `1` (1 day), files generated by Chrome-based browsers in `/tmp` will be removed after these number of days (ignored when using Firefox).

If you use Selenium for long-running sessions and expect browsers to be running for longer than 2 hours, either do
not set `SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP` to `true` (leave the default value of `false`), or tweak
`SE_BROWSER_LEFTOVERS_PROCESSES_SECS` to set a value higher than your expected long-running browser processes.

``` bash
$ docker run -e SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP=true --shm-size="2g" selenium/node-chrome:4.33.0-20250606
```

With the previous command, the cleanup will be enabled with the default timings.

``` bash
$ docker run -e SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP=true \
-e SE_BROWSER_LEFTOVERS_INTERVAL_SECS=7200 \
-e SE_BROWSER_LEFTOVERS_PROCESSES_SECS=3600 \
-e SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS=2 \
--shm-size="2g" selenium/node-chrome:4.33.0-20250606
```

With the previous command, the cleanup will be enabled, but will run every 2 hours (instead of 1), will kill browsers
running longer than 1 hour (instead of 2 hours), and will remove temp files older than 2 days (instead of 1).

---

## Mask sensitive information in console logs

Few variables output like password, secret, etc. are masked in console logs. For debugging purposes, you can disable it by setting `SE_MASK_SECRETS` to `false`

While creating bash script, your can mask the output by using syntax `echo "Current value is $(mask ${YOUR_VARIABLE})`

`SE_MASK_SECRETS_MIN_LENGTH` default is `3`. It means a long string will be masked to `***` to avoid exposing length for brute force attack.

## Secure connection

By default, there are default self-signed certificates available in the image in location `/opt/selenium/secrets` includes
- `server.jks`: truststore file to configure for JVM via system property `javax.net.ssl.trustStore` when start the server.
- `server.pass`: file contains the truststore password for JVM via system property `javax.net.ssl.trustStorePassword`.
- `tls.crt`: Server certificate for https connection is set to Selenium option `--https-certificate`.
- `tls.key`: Server private key (in PKCS8 format) for https connection is set to Selenium option `--https-private-key`.

There are environment variables to configure the secure connection:

| Environment variables                 | Default                             | Option of | Description                                   |
|---------------------------------------|-------------------------------------|-----------|-----------------------------------------------|
| SE_ENABLE_TLS                         | `false`                             |           | Enable secure connection with default configs |
| SE_JAVA_SSL_TRUST_STORE               | `/opt/selenium/secrets/server.jks`  | JVM       |                                               |
| SE_JAVA_SSL_TRUST_STORE_PASSWORD      | `/opt/selenium/secrets/server.pass` | JVM       |                                               |
| SE_JAVA_DISABLE_HOSTNAME_VERIFICATION | `true`                              | JVM       | Disable host checks for components internally |
| SE_HTTPS_CERTIFICATE                  | `/opt/selenium/secrets/tls.crt`     | Selenium  | Set to CLI option `--https-certificate`       |
| SE_HTTPS_PRIVATE_KEY                  | `/opt/selenium/secrets/tls.key`     | Selenium  | Set to CLI option `--https-private-key`       |

Via volume mount, you can replace the default certificates with your own certificates.

The self-signed certificate also needs to be trusted by the client (add to system widely bundle trusted CA) to avoid error message relates to SSL handshake when creating RemoteWebDriver.

Refer to sample: [`docker-compose-v3-full-grid-secure.yml`](docker-compose-v3-full-grid-secure.yml)

## Browser language and locale

Different browsers have different ways to set the language and locale from binding.

### Firefox

Firefox can be configured to use a specific language and locale by setting the profile preference when create WebDriver from binding. In addition, language pack need to be installed as add-on for browser UI language to take effect. For example, to set the browser language and locale to `vi-VN`, you can use the following steps:

Get the latest Firefox language pack for the desired language e.g. https://download.mozilla.org/?product=firefox-langpack-latest-SSL&lang=vi. Then, you can install the language pack as an add-on when creating the RemoteWebDriver instance.

```python
profile = webdriver.FirefoxProfile()
profile.set_preference('intl.accept_languages', 'vi-VN,vi')
profile.set_preference('intl.locale.requested', 'vi-VN,vi')
options = FirefoxOptions()
options.profile = profile
driver = webdriver.Remote(options=options, command_executor="http://selenium-hub:4444/wd/hub")
webdriver.Firefox.install_addon(driver, "/local/path/to/vi.xpi")
driver.get('https://google.com')
```

There is a [script](NodeFirefox/get_lang_package.sh) to get all available language packs for a given Firefox version. You can run the script to get the language packs to your source. For example:

```bash
FIREFOX_VERSION=$(docker run --rm --entrypoint="" selenium/node-firefox:latest firefox --version | awk '{print $3}') \
&& ./NodeFirefox/get_lang_package.sh ${FIREFOX_VERSION} /local/path/to/download
```

Or, you can mount the container directory `$(readlink -f $(which firefox)))/distribution/extensions` to host directory to access packs were pre-built in the container for using in your test script.

## Managing processes in container

[Supervisor](http://supervisord.org/configuration.html) is used to manage processes and logs in the container. Few configuration for `supervisord` can be set via environment variables as below:

| Environment variables        | Default                | `supervisord` config    |
|------------------------------|------------------------|-------------------------|
| SE_SUPERVISORD_LOG_LEVEL     | `info`                 | supervisord.loglevel    |
| SE_SUPERVISORD_CHILD_LOG_DIR | `/tmp`                 | supervisord.childlogdir |
| SE_SUPERVISORD_LOG_FILE      | `/tmp/supervisord.log` | supervisord.logfile     |
| SE_SUPERVISORD_PID_FILE      | `/tmp/supervisord.pid` | supervisord.pidfile     |

___

## Building the images

Clone the repo and from the project directory root you can build everything by running:

``` bash
$ VERSION=local make build
```

If you need to configure environment variables in order to build the image (http proxy for instance), 
simply set an environment variable `BUILD_ARGS` that contains the additional variables to pass to the 
docker context (this will only work with docker >= 1.9)

``` bash
$ BUILD_ARGS="--build-arg http_proxy=http://acme:3128 --build-arg https_proxy=http://acme:3128" make build
```

_Note: Omitting_ `VERSION=local` _will build the images with the released version but replacing the date for the 
current one._

If you want to build the image with the host UID/GID, simply set an environment variable `BUILD_ARGS`

``` bash
$ BUILD_ARGS="--build-arg UID=$(id -u) --build-arg GID=$(id -g)" make build
```

If you want to build the image with different default user/password, simply set an environment variable `BUILD_ARGS`

``` bash
$ BUILD_ARGS="--build-arg SEL_USER=yourseluser --build-arg SEL_PASSWD=welcome" make build
```
___

# Build the images with specific versions

Based on the latest Dockerfile (by cloning the repo and from the project directory root), you can build the images with a specific combination of Selenium Grid, and browser versions.

For example, you would like to build `node-chrome` and `standalone-chrome` images with the Grid based version `4.17.0`, Chrome browser versions `119`, `120`, `123` respectively.

```bash
$ ./tests/build-backward-compatible/bootstrap.sh 4.17.0 119,120,123 chrome
```

In generic, the script takes the following arguments:
- `$1` (mandatory): Selenium Grid version. Details are fetching from matrix [file](tests/build-backward-compatible/selenium-matrix.yml)
- `$2` (mandatory): Browser major version, multiple values separated by comma. Details are fetching from matrix [file](tests/build-backward-compatible/browser-matrix.yml)
- `$3` (optional): browser name. If not provided, it will iterate over all the browsers (`chrome`, `edge`, `firefox`)
- `$4` (optional): Push image to registry. By default, it is `false`. If you want to push the image to the registry, set it to `true` (required Docker login to your namespace done before running the script).

To set your namespace for the images, you can set the environment variable `NAME` before running the script. For example:

```bash
$ export NAME=artifactory.yourcompany.com/selenium
$ ./tests/build-backward-compatible/bootstrap.sh 4.17.0 119,120,123 chrome
```

After running the script, you will see list images with a full tag to pin specific Grid and browser version following [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention)

---

## Upgrade browser version in the images

Selenium server, browser and driver are pre-installed in the image. In case you would like to remain on the same Selenium version and just upgrade the browser and its driver to the latest. You can follow below steps

Clone the repo and from the project directory root you can upgrade by running:

```bash
$ VERSION=$EXPECTED_SELENIUM_VERSION make chrome_upgrade_version
```
For example: `VERSION=4.16.1 make chrome_upgrade_version`

The new image has tag `$VERSION_YYYYMMDD` where `YYYYMMDD` is the current date.

```bash
$ VERSION=$SELENIUM_VERSION make firefox_upgrade_version
```

```bash
$ VERSION=$SELENIUM_VERSION make edge_upgrade_version
```

You can refer to detail commands in the [Makefile](Makefile) file.

---

## Waiting for the Grid to be ready

It is a good practice to check first if the Grid is up and ready to receive requests, this can be done by checking the `/wd/hub/status` endpoint.

A Grid that is ready, composed of a hub and two nodes, could look like this:

```json
{
  "value": {
    "ready": true,
    "message": "Selenium Grid ready.",
    "nodes": [
      {
        "id": "6c0a2c59-7e99-469d-bbfc-313dc638797c",
        "uri": "http:\u002f\u002f172.19.0.3:5555",
        "maxSessions": 4,
        "stereotypes": [
          {
            "capabilities": {
              "browserName": "firefox"
            },
            "count": 4
          }
        ],
        "sessions": [
        ]
      },
      {
        "id": "26af3363-a0d8-4bd6-a854-2c7497ed64a4",
        "uri": "http:\u002f\u002f172.19.0.4:5555",
        "maxSessions": 4,
        "stereotypes": [
          {
            "capabilities": {
              "browserName": "chrome"
            },
            "count": 4
          }
        ],
        "sessions": [
        ]
      }
    ]
  }
}
```

The `"ready": true` value indicates that the Grid is ready to receive requests. This status can be polled through a
script before running any test, or it can be added as a [HEALTHCHECK](https://docs.docker.com/engine/reference/run/#healthcheck)
when the docker container is started.

### Adding a [HEALTHCHECK](https://docs.docker.com/engine/reference/run/#healthcheck) to the Grid

The script [check-grid.sh](Base/check-grid.sh), which is included in the images, can be used to poll the Grid status.

This example checks the status of the Grid every 15 seconds, it has a timeout of 30 seconds when the check is done,
and it retries up to 5 times until the container is marked as unhealthy. Please use adjusted values to fit your needs,
(if needed) replace the `--host` and `--port` parameters for the ones used in your environment.

``` bash
$ docker network create grid
$ docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub \
  --health-cmd='/opt/bin/check-grid.sh --host 0.0.0.0 --port 4444' \
  --health-interval=15s --health-timeout=30s --health-retries=5 \
  selenium/hub:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
    selenium/node-chrome:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
    selenium/node-edge:4.33.0-20250606
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
    selenium/node-firefox:4.33.0-20250606

```
**Note:** The `\` line delimiter won't work on Windows-based terminals, try either `^` or a backtick.

The container health status can be checked by doing `docker ps` and verifying the `(healthy)|(unhealthy)` status or by
inspecting it in the following way:

```bash
$ docker inspect --format='{{json .State.Health.Status}}' selenium-hub
"healthy"
```

### Using a bash script to wait for the Grid

A common problem known in docker is that a running container does not always mean that the application inside it is ready.
A simple way to tackle this is by using a "wait-for-it" script, more information can be seen [here](https://docs.docker.com/compose/startup-order/).

The following script is an example of how this can be done using bash, but the same principle applies if you want to do this with the programming language used to write the tests.
In the example below, the script will poll the status endpoint every second. If the grid does not become ready within 30 seconds, the script will exit with an error code.

```bash
#!/bin/bash
# wait-for-grid.sh

set -e
url="http://localhost:4444/wd/hub/status"
wait_interval_in_seconds=1
max_wait_time_in_seconds=30
end_time=$((SECONDS + max_wait_time_in_seconds))
time_left=$max_wait_time_in_seconds

while [ $SECONDS -lt $end_time ]; do
    response=$(curl -sL "$url" | jq -r '.value.ready')
    if [ -n "$response"  ]  && [ "$response" ]; then
        echo "Selenium Grid is up - executing tests"
        break
    else
        echo "Waiting for the Grid. Sleeping for $wait_interval_in_seconds second(s). $time_left seconds left until timeout."
        sleep $wait_interval_in_seconds
        time_left=$((time_left - wait_interval_in_seconds))
    fi
done

if [ $SECONDS -ge $end_time ]; then
    echo "Timeout: The Grid was not started within $max_wait_time_in_seconds seconds."
    exit 1
fi
```
> Will require `jq` installed via `apt-get`, else the script will keep printing `Waiting` without completing the execution.

**Note:** If needed, replace `localhost` and `4444` for the correct values in your environment. Also, this script is polling indefinitely, you might want
to tweak it and establish a timeout.

Let's say that the normal command to execute your tests is `mvn clean test`. Here is a way to use the above script and execute your tests:

```bash
$ ./wait-for-grid.sh && mvn clean test
```

Like this, the script will poll until the Grid is ready, and then your tests will start.

___

## Install certificates for Chromium-based browsers

By default, the based image is installed `libnss3-tools` and initializes `/home/seluser/.pki/nssdb`,
so you are able to add your certs with rootless.
If you need to install custom certificates, CA, intermediate CA,
or client certificates (for example, enterprise internal CA)
you can create your own docker image from selenium node image.
The Chromium-based browser uses `nssdb` as a certificate store.
You can then install all required internal certificates in your Dockerfile like this:

There is a utility script packaged in the image that can be used to add your certificates to the `nssdb` store and the bundle CA.
The script is `/opt/bin/add-cert-helper.sh`.

- Create a Dockerfile that uses the selenium node image as a base and copies the script to the container, and executes it.
For example, [Dockerfile](tests/customCACert/Dockerfile)

- If you have to create a set of different certificates and node images. You can create a bootstrap script to do that in one-shot.
For example, [bootstrap.sh](tests/customCACert/bootstrap.sh)

The above example can be tested with the following command:

```bash
make test_custom_ca_cert
# ./tests/customCACert/bootstrap.sh
```

You can find more information [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux/cert_management.md)

This way the certificates will be installed and the node will start automatically as before.
___

## Alternative method: Add certificates to existing Selenium based images for browsers

As an alternative, you can add your certificate files to existing Selenium images. This practical example
assumes you have a known image to use as a build image and have a way to publish new images to your local
docker registry.

This example uses a RedHat-based distro as a build image (Rocky Linux) but it can be *any* Linux image of your choice.
Please note that build instruction will vary between distributions. You can check the instructions for Ubuntu
in the previous example.

The example also assumes your internal CA is already in */etc/pki/ca-trust/source/anchors/YOUR_CA.pem*,
the default location for Rocky Linux. Alternatively, you can also provide these files from your host and 
copy them into the build image.

For Chrome and Edge browsers, the recipe is the same, just adapt the image name (node-chrome or node-edge):
```
# Get a standard image for creating nssdb file
FROM rockylinux:8.6 as build
RUN yum install -y nss-tools
RUN mkdir -p -m755 /seluser/.pki/nssdb \
    && certutil -d sql:/seluser/.pki/nssdb -N --empty-password \
    && certutil -d sql:/seluser/.pki/nssdb -A -t "C,," -n YOUR_CA -i /etc/pki/ca-trust/source/anchors/YOUR_CA.pem \
    && chown -R 1200:1201 /seluser

# Start from Selenium image and add relevant files from build image
FROM selenium/node-chrome:4.33.0-20250606
USER root
COPY --from=build /seluser/ /home/seluser/
USER seluser
```

Example for Firefox:
```
# Get a standard image for working on
FROM rockylinux:8.6 as build
RUN mkdir -p "/distribution" "/certs" && \
    cp /etc/pki/ca-trust/source/anchors/YOUR_CA*.pem /certs/ && \
    echo '{ "policies": { "Certificates": { "Install": ["/opt/firefox-latest/YOUR_CA.pem"] }} }' >"/distribution/policies.json"

# Start from Selenium image and add relevant files from build image
FROM selenium/node-firefox:4.33.0-20250606
USER root
COPY --from=build /certs /opt/firefox-latest
COPY --from=build /distribution /opt/firefox-latest/distribution
USER seluser
```
___

## Debugging

This project uses [x11vnc](https://github.com/LibVNC/x11vnc) as a VNC server to allow users to inspect what is happening
inside the container. Users can connect to this server in two ways:

### Using a VNC client

The VNC server is listening to port 5900, you can use a VNC client and connect to it. Feel free to map port 5900 to 
any free external port that you wish.

The internal 5900 port remains the same because that is the configured port for the VNC server running inside the container. 
You can override it with the `SE_VNC_PORT` environment variable in case you want to use `--net=host`.

Here is an example with the standalone images, the same concept applies to the node images.
``` bash
$ docker run -d -p 4444:4444 -p 5900:5900 --shm-size="2g" selenium/standalone-chrome:4.33.0-20250606
$ docker run -d -p 4445:4444 -p 5901:5900 --shm-size="2g" selenium/standalone-edge:4.33.0-20250606
$ docker run -d -p 4446:4444 -p 5902:5900 --shm-size="2g" selenium/standalone-firefox:4.33.0-20250606
```

Then, you would use in your VNC client:
- Port 5900 to connect to the Chrome container
- Port 5901 to connect to the Edge container
- Port 5902 to connect to the Firefox container

If you get a prompt asking for a password, it is: `secret`. If you wish to change this, 
you can set the environment variable `SE_VNC_PASSWORD`.

If you want to run VNC without password authentication you can set the environment variable `SE_VNC_NO_PASSWORD=true`.

If you want to run VNC in view-only mode you can set the environment variable `SE_VNC_VIEW_ONLY=true`.

If you want to modify the open file descriptor limit for the VNC server process you can set the environment variable `SE_VNC_ULIMIT=4096`.

### Using your browser (no VNC client is needed)

This project uses [noVNC](https://github.com/novnc/noVNC) to allow users to inspect visually container activity with
their browser. This might come in handy if you cannot install a VNC client on your machine. Port 7900 is used to start
noVNC, so you will need to connect to that port with your browser.

Similarly to the previous section, feel free to map port 7900 to any free external port that you wish.
You can also override it with the `SE_NO_VNC_PORT` environment variable in case you want to use `--net=host`.

Here is an example with the standalone images, the same concept applies to the node images.
``` bash
$ docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-chrome:4.33.0-20250606
$ docker run -d -p 4445:4444 -p 7901:7900 --shm-size="2g" selenium/standalone-edge:4.33.0-20250606
$ docker run -d -p 4446:4444 -p 7902:7900 --shm-size="2g" selenium/standalone-firefox:4.33.0-20250606
```

Then, you would use in your browser:
- http://localhost:7900/ to connect to the Chrome container
- http://localhost:7901/ to connect to the Edge container
- http://localhost:7902/ to connect to the Firefox container

If you get a prompt asking for a password, it is: `secret`.

### Disabling VNC
If You are running low on resources, or simply don't need to inspect running sessions, it is possible to not run VNC at all.
Just set 
```SE_START_VNC=false```
environment variable on the grid startup.

___

## Tracing in Grid

In order to enable tracing in the Selenium Grid container, the following commands can be executed:

```bash
docker network create grid
docker run -d -p 16686:16686 -p 4317:4317 --net grid --name jaeger jaegertracing/all-in-one:1.54
docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:4.33.0-20250606
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
	-e SE_ENABLE_TRACING=true \
	-e SE_OTEL_TRACES_EXPORTER=otlp \
	-e SE_OTEL_EXPORTER_ENDPOINT=http://jaeger:4317 \
    selenium/node-chrome:4.33.0-20250606
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
	-e SE_ENABLE_TRACING=true \
	-e SE_OTEL_TRACES_EXPORTER=otlp \
	-e SE_OTEL_EXPORTER_ENDPOINT=http://jaeger:4317 \
    selenium/node-edge:4.33.0-20250606
docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    --shm-size="2g" \
	-e SE_ENABLE_TRACING=true \
	-e SE_OTEL_TRACES_EXPORTER=otlp \
	-e SE_OTEL_EXPORTER_ENDPOINT=http://jaeger:4317 \
    selenium/node-firefox:4.33.0-20250606
```

You can also refer to the below docker compose yaml files to be able to start a simple grid (or) a dynamic grid.

* Simple Grid [v3 yaml file](docker-compose-v3-tracing.yml)
* Simple Grid [v2 yaml file](docker-compose-v2-tracing.yml)
* Dynamic Grid [v3 yaml file](docker-compose-v3-full-grid-tracing.yml)

You can view the [Jaeger UI](http://localhost:16686/) and trace your request.

By default, the tracing is enabled in Grid components. Without trace exporter endpoint, it will look up a local instance e.g. `localhost/[0:0:0:0:0:0:0:1]:4117`.
In container logs you can see few lines like below:

```bash
ERROR (ThrottlingLogger.dolog) Failed to export spans.
  The request could not be executed. Error message: Failed to connect to localhost/[0:0:0:0:0:0:0:1]:4117
  java.net.ConnectException: Failed to connect to localhost/[0:0:0:0:0:0:0:1]:4317 
at okhttp3.internal.connection.RealConnection.connectSocket(RealConnection.kt:297)
at okhttp3.internal.connection. ExchangeFinder.findConnection (Exchangefinder.kt: 226)
at okhttp3.internal.connection.okhttps.internal.connection.RealConnection.connect(RealConnection.kt:207)
```

In this case, just simply set `SE_ENABLE_TRACING=false` to all components container to disable tracing (each component exports its own traces).

___

## Troubleshooting

All output gets sent to stdout, so it can be inspected by running:
``` bash
$ docker logs -f <container-id|container-name>
```

You can increase the log output by passing environment variable to the containers:
```
SE_OPTS="--log-level FINE"
```

### `--shm-size="2g"`

Why is `--shm-size 2g` necessary?
> This is a known workaround to avoid the browser crashing inside a docker container, here are the documented issues for
[Chrome](https://code.google.com/p/chromium/issues/detail?id=519952) and [Firefox](https://bugzilla.mozilla.org/show_bug.cgi?id=1338771#c10).
The shm size of 2gb is arbitrary but known to work well, your specific use case might need a different value, it is recommended
to tune this value according to your needs.


### Headless

If you see the following selenium exceptions:

`Message: invalid argument: can't kill an exited process`

or

`Message: unknown error: Chrome failed to start: exited abnormally`

or

` [DriverServiceSessionFactory.apply] - Error while creating session with the driver service. Stopping driver service: java.util.concurrent.TimeoutException`

The reason _might_ be that you've set the `SE_START_XVFB` environment variable to `false`, but forgot to 
actually run Firefox, Chrome or Edge in headless mode.

### Mounting volumes to retrieve downloaded files

A common scenario is mounting a volume to the browser 
container in order to retrieve downloaded files. This
works well in Windows and macOS but not without 
workarounds in Linux. For more details, check this
well-documented [issue](https://github.com/SeleniumHQ/docker-selenium/issues/1095).

For example, while using Linux, you might be starting a
container in the following way:

```bash
docker run -d -p 4444:4444 --shm-size="2g" \
  -v /home/ubuntu/files:/home/seluser/Downloads \
  selenium/standalone-chrome:4.33.0-20250606
```

That will mount the host `/home/ubuntu/files` directory
to the `/home/seluser/Downloads` inside the container
(default browser's downloads directory). The
problem happens because the volume will be mounted as
`root`; therefore, the browser cannot write a file to
that directory because it is running under the user 
`seluser`. This happens because that is how Docker mounts
volumes in Linux, more details in this [issue](https://github.com/moby/moby/issues/2259).

A workaround for this is to create a directory on the
host and change its permissions **before mounting the volume**. 
Depending on your user permissions, you might need to use 
`sudo` for some of these commands:

```bash
mkdir /home/ubuntu/files
chown 1200:1201 /home/ubuntu/files
```

After doing this, you should be able to download files
to the mounted directory. If you have a better workaround,
please send us a pull request!

### Mounting volumes to retrieve video files

Similar to mount volumes to retrieve downloaded files. For video files, you might need to do the same

```bash
mkdir /tmp/videos
chown 1200:1201 /tmp/videos
```

### Websocket connections per session get exhausted

> org.openqa.selenium.remote.http.ConnectionFailedException: JdkWebSocket initial request execution error`

This was reported in [#2850](https://github.com/SeleniumHQ/docker-selenium/issues/2850).
Actually, from Grid version v4.26.0+, in Node CLI option `--connection-limit-per-session` (`SE_NODE_CONNECTION_LIMIT_PER_SESSION` environment variable) is set to `10` by default. Let X be the maximum number of websocket connections per session.This will ensure one session is not able to exhaust the connection limit of the host. Websocket connection might come from enable CDP, BiDi.

Your test scenario or test framework implementation might be creating more than `X` connections per session, which will lead to the error above. You can optimize your implementation to use less connections per session, or you can increase the limit by setting the environment variable `SE_NODE_CONNECTION_LIMIT_PER_SESSION` to a value higher than `10` to allow more connections per session.

## Stargazers over time
[![Stargazers over time](https://starchart.cc/SeleniumHQ/docker-selenium.svg?variant=adaptive)](https://starchart.cc/SeleniumHQ/docker-selenium)
