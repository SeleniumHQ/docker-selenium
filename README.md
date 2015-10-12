# Selenium Docker

The project is made possible by volunteer contributors who have put in thousands of hours of their own time, and made the source code freely available under the [Apache License 2.0](https://github.com/SeleniumHQ/docker-selenium/blob/master/LICENSE.md).

## Docker images for Selenium Standalone Server Hub and Node configurations with Chrome and Firefox
[![Circle CI](https://circleci.com/gh/SeleniumHQ/docker-selenium.svg?style=svg)](https://circleci.com/gh/SeleniumHQ/docker-selenium)

[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/SeleniumHQ/docker-selenium?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Images included:
- __selenium/base__: Base image which includes Java runtime and Selenium JAR file
- __selenium/hub__: Image for running a Selenium Grid Hub
- __selenium/node-base__: Base image for Selenium Grid Nodes which includes a virtual desktop environment and VNC support
- __selenium/node-chrome__: Selenium node with Chrome installed, needs to be connected to a Selenium Grid Hub
- __selenium/node-firefox__: Selenium node with Firefox installed, needs to be connected to a Selenium Grid Hub
- __selenium/standalone-chrome__: Selenium standalone with Chrome installed
- __selenium/standalone-firefox__: Selenium standalone with Firefox installed
- __selenium/standalone-chrome-debug__: Selenium standalone with Chrome installed and runs a VNC server
- __selenium/standalone-firefox-debug__: Selenium standalone with Firefox installed and runs a VNC server
- __selenium/node-chrome-debug__: Selenium node with Chrome installed and runs a VNC server, needs to be connected to a Selenium Grid Hub
- __selenium/node-firefox-debug__: Selenium node with Firefox installed and runs a VNC server, needs to be connected to a Selenium Grid Hub

## Running the images
 
When executing docker run for an image with chrome browser please add volume mount `-v /dev/shm:/dev/shm` to use the host's shared memory.

``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome:2.48.2
```

This is a workaround to node-chrome crash in docker container issue: https://code.google.com/p/chromium/issues/detail?id=519952 


### Standalone Chrome and Firefox

``` bash
$ docker run -d -p 4444:4444 selenium/standalone-chrome:2.48.2
# OR
$ docker run -d -p 4444:4444 selenium/standalone-firefox:2.48.2
```

_Note: Only one standalone image can run on port_ `4444` _at a time._

To inspect visually what the browser is doing use the `standalone-chrome-debug` or `standalone-firefox-debug` images. See [Debugging](#debugging) section for details.

### Selenium Grid Hub

``` bash
$ docker run -d -p 4444:4444 --name selenium-hub selenium/hub:2.48.2
```

### Chrome and Firefox Grid Nodes

``` bash
$ docker run -d --link selenium-hub:hub selenium/node-chrome:2.48.2
$ docker run -d --link selenium-hub:hub selenium/node-firefox:2.48.2
```

### Java Environment Options

You can pass JAVA_OPTS environment variable to selenium java processes.

``` bash
$ docker run -d -p 4444:4444 -e JAVA_OPTS=-Xmx512m --name selenium-hub selenium/hub:2.48.2
```

## Building the images

Ensure you have the `ubuntu:15.04` base image downloaded, this step is _optional_ since Docker takes care of downloading the parent base image automatically.

``` bash
$ docker pull ubuntu:15.04
```

Clone the repo and from the project directory root you can build everything by running:

``` bash
$ VERSION=local make build
```

_Note: Omitting_ `VERSION=local` _will build the images with the current version number thus overwriting the images downloaded from [Docker Hub](https://registry.hub.docker.com/)._

## Using the images

##### Example: Spawn a container for testing in Chrome:

``` bash
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:2.48.2
$ CH=$(docker run --rm --name=ch \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    selenium/node-chrome:2.48.2)
```

_Note:_ `-v /e2e/uploads:/e2e/uploads` _is optional in case you are testing browser uploads on your web app you will probably need to share a directory for this._

##### Example: Spawn a container for testing in Firefox:

This command line is the same as for Chrome. Remember that the Selenium running container is able to launch either Chrome or Firefox, the idea around having 2 separate containers, one for each browser is for convenience plus avoiding certain `:focus` issues your web app may encounter during end-to-end test automation.

``` bash
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:2.48.2
$ FF=$(docker run --rm --name=fx \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    selenium/node-firefox:2.48.2)
```

_Note: Since a Docker container is not meant to preserve state and spawning a new one takes less than 3 seconds you will likely want to remove containers after each end-to-end test with_ `--rm` _command. You need to think of your Docker containers as single processes, not as running virtual machines, in case you are familiar with [Vagrant](https://www.vagrantup.com/)._

## Debugging

In the event you wish to visually see what the browser is doing you will want to run the `debug` variant of node or standalone images:
``` bash
$ docker run -d -P --link selenium-hub:hub selenium/node-chrome-debug:2.48.2
$ docker run -d -P --link selenium-hub:hub selenium/node-firefox-debug:2.48.2
```

And for standalone: 
``` bash
$ docker run -d -p 4444:4444 selenium/standalone-chrome-debug:2.48.2
# OR
$ docker run -d -p 4444:4444 selenium/standalone-firefox-debug:2.48.2
```

You can acquire the port that the VNC server is exposed to by running:
``` bash
$ docker port <container-name|container-id> 5900
#=> 0.0.0.0:49338
```

In case you have [RealVNC](https://www.realvnc.com/) binary `vnc` in your path, you can always take a look, view only to avoid messing around your tests with an unintended mouse click or keyboard interrupt:
``` bash
$ ./bin/vncview 127.0.0.1:49160
```

If you are running [Boot2Docker](https://docs.docker.com/installation/mac/) on OS X then you already have a [VNC client](http://www.davidtheexpert.com/post.php?id=5) built-in. You can connect by entering `vnc://<boot2docker-ip>:49160` in Safari or [Alfred](http://www.alfredapp.com/).

When you are prompted for the password it is `secret`. If you wish to change this then you should either change it in the `/NodeBase/Dockerfile` and build the images yourself, or you can define a Docker image that derives from the posted ones which reconfigures it:
``` dockerfile
#FROM selenium/node-chrome-debug:2.48.2
#FROM selenium/node-firefox-debug:2.48.2
#Choose the FROM statement that works for you.

RUN x11vnc -storepasswd <your-password-here> /home/seluser/.vnc/passwd
```

##### Look around

``` bash
$ docker images
#=>
REPOSITORY                      TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
selenium/node-firefox           2.48.2              69f762d0d79e        29 minutes ago      552.1 MB
selenium/node-chrome            2.48.2              9dd73160660b        30 minutes ago      723.6 MB
selenium/node-base              2.48.2              1b7a0b7024b1        32 minutes ago      426.1 MB
selenium/hub                    2.48.2              2570bbb98229        33 minutes ago      394.4 MB
selenium/base                   2.48.2              33478d455dab        33 minutes ago      362.6 MB
ubuntu                          15.04               013f3d01d247        6 days ago          131.4 MB
```

### Troubleshooting

All output is sent to stdout so it can be inspected by running:
``` bash
$ docker logs -f <container-id|container-name>
```
