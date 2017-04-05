# Selenium Docker

The project is made possible by volunteer contributors who have put in thousands of hours of their own time, and made the source code freely available under the [Apache License 2.0](https://github.com/SeleniumHQ/docker-selenium/blob/master/LICENSE.md).

## Community

### [SeleniumHQ Slack](https://seleniumhq.herokuapp.com/)

### IRC (&#35;selenium at Freenode)

## Docker images for Selenium Standalone Server Hub and Node configurations with Chrome and Firefox
[Travis CI](https://travis-ci.org/SeleniumHQ/docker-selenium)

Images included:
- __selenium/base__: Base image which includes Java runtime and Selenium JAR file
- __selenium/hub__: Image for running a Selenium Grid Hub
- __selenium/node-base__: Base image for Selenium Grid Nodes which includes a virtual desktop environment and VNC support
- __selenium/node-chrome__: Selenium node with Chrome installed, needs to be connected to a Selenium Grid Hub
- __selenium/node-firefox__: Selenium node with Firefox installed, needs to be connected to a Selenium Grid Hub
- __selenium/node-phantomjs__: Selenium node with PhantomJS installed, needs to be connected to a Selenium Grid Hub
- __selenium/standalone-chrome__: Selenium standalone with Chrome installed
- __selenium/standalone-firefox__: Selenium standalone with Firefox installed
- __selenium/standalone-chrome-debug__: Selenium standalone with Chrome installed and runs a VNC server
- __selenium/standalone-firefox-debug__: Selenium standalone with Firefox installed and runs a VNC server
- __selenium/node-chrome-debug__: Selenium node with Chrome installed and runs a VNC server, needs to be connected to a Selenium Grid Hub
- __selenium/node-firefox-debug__: Selenium node with Firefox installed and runs a VNC server, needs to be connected to a Selenium Grid Hub

## 

## Running the images

When executing docker run for an image with chrome browser please add volume mount `-v /dev/shm:/dev/shm` to use the host's shared memory.

``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome:3.3.1-arsenic
```

This is a workaround to node-chrome crash in docker container issue: https://code.google.com/p/chromium/issues/detail?id=519952


### Standalone Chrome and Firefox

``` bash
$ docker run -d -p 4444:4444 selenium/standalone-chrome:3.3.1-arsenic
# OR
$ docker run -d -p 4444:4444 selenium/standalone-firefox:3.3.1-arsenic
```

_Note: Only one standalone image can run on port_ `4444` _at a time._

To inspect visually what the browser is doing use the `standalone-chrome-debug` or `standalone-firefox-debug` images. See [Debugging](#debugging) section for details.

### Selenium Grid Hub and Nodes

``` bash
$ docker run -d -p 4444:4444 --name selenium-hub selenium/hub:3.3.1-arsenic
$ docker run -d --link selenium-hub:hub selenium/node-chrome:3.3.1-arsenic
$ docker run -d --link selenium-hub:hub selenium/node-firefox:3.3.1-arsenic
```

## Configuring the containers

### JAVA_OPTS Java Environment Options

You can pass `JAVA_OPTS` environment variable to java process.

``` bash
$ docker run -d -p 4444:4444 -e JAVA_OPTS=-Xmx512m --name selenium-hub selenium/hub:3.3.1-arsenic
```

### SE_OPTS Selenium Configuration Options

You can pass `SE_OPTS` variable with additional commandline parameters for starting a hub or a node.

``` bash
$ docker run -d -p 4444:4444 -e SE_OPTS="-debug true" --name selenium-hub selenium/hub:3.2.0-actinium
```

### PHANTOMJS_OPTS PhantomJS Configuration Options

``` bash
$ docker run -d -e PHANTOMJS_OPTS="--ignore-ssl-errors=true" --link selenium-hub:hub selenium/node-phantomjs:3.3.1-arsenic
```

You can pass `SE_OPTS` variable with additional commandline parameters for starting a PhantomJS node.

## Building the images

Clone the repo and from the project directory root you can build everything by running:

``` bash
$ VERSION=local make build
```

If you need to configure environment variable in order to build the image (http proxy for instance), simply set an environment variable `BUILD_ARGS` that contains the additional variables to pass to the docker context (this will only work with docker >= 1.9)

``` bash
$ BUILD_ARGS="--build-arg http_proxy=http://acme:3128 --build-arg https_proxy=http://acme:3128" make build
```

_Note: Omitting_ `VERSION=local` _will build the images with the current version number thus overwriting the images downloaded from [Docker Hub](https://hub.docker.com/r/selenium/)._

## Using the images

##### Example: Spawn a container for testing in Chrome:

``` bash
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:3.3.1-arsenic
$ CH=$(docker run --rm --name=ch \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    selenium/node-chrome:3.3.1-arsenic)
```

_Note:_ `-v /e2e/uploads:/e2e/uploads` _is optional in case you are testing browser uploads on your web app you will probably need to share a directory for this._

##### Example: Spawn a container for testing in Firefox:

This command line is the same as for Chrome. Remember that the Selenium running container is able to launch either Chrome or Firefox, the idea around having 2 separate containers, one for each browser is for convenience plus avoiding certain `:focus` issues your web app may encounter during end-to-end test automation.

``` bash
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:3.3.1-arsenic
$ FF=$(docker run --rm --name=fx \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    selenium/node-firefox:3.3.1-arsenic)
```

_Note: Since a Docker container is not meant to preserve state and spawning a new one takes less than 3 seconds you will likely want to remove containers after each end-to-end test with_ `--rm` _command. You need to think of your Docker containers as single processes, not as running virtual machines, in case you are familiar with [Vagrant](https://www.vagrantup.com/)._

## Debugging

In the event you wish to visually see what the browser is doing you will want to run the `debug` variant of node or standalone images. A VNC server will run on port 5900. You are free to map that to any free external port that you wish.  Example: <port4VNC>: 5900) you will only be able to run 1 node per port so if you wish to include a second node, or more, you will have to use different ports, the 5900 as the internal port will have to remain the same though as thats the VNC service on the node. The second example below shows how to run multiple nodes and with different VNC ports open:
``` bash
$ docker run -d -P -p <port4VNC>:5900 --link selenium-hub:hub selenium/node-chrome-debug:3.3.1-arsenic
$ docker run -d -P -p <port4VNC>:5900 --link selenium-hub:hub selenium/node-firefox-debug:3.3.1-arsenic
```
e.g.:
``` bash
$ docker run -d -P -p 5900:5900 --link selenium-hub:hub selenium/node-chrome-debug:3.3.1-arsenic
$ docker run -d -P -p 5901:5900 --link selenium-hub:hub selenium/node-firefox-debug:3.3.1-arsenic
```

to connect to the Chrome node on 5900 and the Firefox node on 5901 (assuming those node are free, and reachable).

And for standalone:
``` bash
$ docker run -d -p 4444:4444 -p <port4VNC>:5900 selenium/standalone-chrome-debug:3.3.1-arsenic
# OR
$ docker run -d -p 4444:4444 -p <port4VNC>:5900 selenium/standalone-firefox-debug:3.3.1-arsenic
```
or
``` bash
$ docker run -d -p 4444:4444 -p 5900:5900 selenium/standalone-chrome-debug:3.3.1-arsenic
# OR
$ docker run -d -p 4444:4444 -p 5901:5900 selenium/standalone-firefox-debug:3.3.1-arsenic
```

You can acquire the port that the VNC server is exposed to by running:
(In this case our port mapping looks like 49338:5900 for our node)
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
#FROM selenium/node-chrome-debug:3.3.1-arsenic
#FROM selenium/node-firefox-debug:3.3.1-arsenic
#Choose the FROM statement that works for you.

RUN x11vnc -storepasswd <your-password-here> /home/seluser/.vnc/passwd
```

### Troubleshooting

All output is sent to stdout so it can be inspected by running:
``` bash
$ docker logs -f <container-id|container-name>
```
