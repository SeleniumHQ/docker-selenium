---
description: Selenium Grid Node with Dynamic capabilities
---
# Selenium Grid Node with Dynamic Capabilities

### This image provides a [Selenium Grid Node](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node) that creates child Docker browser containers on fly, , meant to be used together with a [Selenium Grid Hub](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node), which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

## Dynamic Grid

Grid 4 has the ability to start Docker containers on demand, this means that it starts
a Docker container in the background for each new session request, the test gets executed
there, and when the test completes, the container gets thrown away.

This execution mode can be used either in the Standalone or Node roles. The "dynamic"
execution mode needs to be told what Docker images to use when the containers get started.
Additionally, the Grid needs to know the URI of the Docker daemon. This configuration can
be placed in a local `toml` file.

More details can be seen at the [Dynamic Grid section in GitHub](https://github.com/SeleniumHQ/docker-selenium/tree/trunk#dynamic-grid).

### Configuration example

You can save this file locally and name it, for example, `config.toml`.

```toml
[docker]
# Configs have a mapping between the Docker image to use and the capabilities that need to be matched to
# start a container with the given image.
configs = [
    "selenium/standalone-firefox:latest", '{"browserName": "firefox"}',
    "selenium/standalone-chrome:latest", '{"browserName": "chrome"}',
    "selenium/standalone-edge:latest", '{"browserName": "MicrosoftEdge"}'
]

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
video-image = "selenium/video:ffmpeg-4.48.0-20260909"

# Uncomment the following section if you are running the node on a separate VM
# Fill out the placeholders with appropriate values
#[server]
#host = <ip-from-node-machine>
#port = <port-from-node-machine>
```

## How to run this image

1. Start a Hub and the Node Docker containers in the same network

This can be expanded to a full Grid deployment, all components deployed individually. The overall
idea is to have the Hub in one virtual machine, and each of the Nodes in separate and more powerful
virtual machines. 

#### macOS/Linux

```bash
$ docker network create grid
$ docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:latest
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub \
    -e SE_EVENT_BUS_PUBLISH_PORT=4442 \
    -e SE_EVENT_BUS_SUBSCRIBE_PORT=4443 \
    -v ${PWD}/config.toml:/opt/bin/config.toml \
    -v ${PWD}/assets:/opt/selenium/assets \
    -v /var/run/docker.sock:/var/run/docker.sock \
    selenium/node-docker:latest
```

#### Windows PowerShell

```powershell
$ docker network create grid
$ docker run -d -p 4442-4444:4442-4444 --net grid --name selenium-hub selenium/hub:latest
$ docker run -d --net grid -e SE_EVENT_BUS_HOST=selenium-hub `
    -e SE_EVENT_BUS_PUBLISH_PORT=4442 `
    -e SE_EVENT_BUS_SUBSCRIBE_PORT=4443 `
    -v ${PWD}/config.toml:/opt/bin/config.toml `
    -v ${PWD}/assets:/opt/selenium/assets `
    -v /var/run/docker.sock:/var/run/docker.sock `
    selenium/node-docker:latest
```

To have the assets saved on your host, please mount your host path to `/opt/selenium/assets`.

Note: If you are mounting a volume in Linux, there is a known issue that can be solved through [this workaround](https://github.com/SeleniumHQ/docker-selenium/tree/trunk#mounting-volumes-to-retrieve-downloaded-files).

When you are done using the Grid, and the containers have exited, the network can be removed with the following command:

``` bash
# Removes the grid network
$ docker network rm grid
```

2. Point your WebDriver tests to http://localhost:4444

3. That's it! 

4. (Optional) To see what is happening inside the container, head to the Grid UI at http://localhost:4444/ui.

* The example above uses `latest` as a tag, but we recommend to full tag to pin a specific browser and Grid version. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/standalone-docker-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```


### Example of a release with Selenium Grid Server 4.48.0, released on 20260909

```
    Selenium Server 4.48.0
    Release date 20260909


e126989f151e        selenium/node-docker   4
e126989f151e        selenium/node-docker   4.48
e126989f151e        selenium/node-docker   4.48.0
e126989f151e        selenium/node-docker   4.48.0-20260909
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
