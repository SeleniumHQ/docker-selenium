# Selenium Docker

The project is made possible by volunteer contributors who have put in thousands of hours of their own time, and made the source code freely available under the [Apache 2.0 license](https://code.google.com/p/selenium/source/browse/COPYING).

## Docker images for Selenium Standalone Server Hub and Node configurations with Chrome and Firefox
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/elgalu/docker-selenium?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Images included:

- __selenium/base__: Base image which includes Java runtime and Selenium jar
- __selenium/hub__: Image for running a Selenium Grid Hub
- __selenium/node-base__: Base image for Selenium Nodes which includes a virtual desktop environment and VNC support
- __selenium/node-chrome__: Selenium node with Chrome installed, needs to be connected to a Selenium Hub
- __selenium/node-firefox__: Selenium node with Firefox installed, needs to be connected to a Selenium Hub
- __selenium/standalone-chrome__: Selenium standalone with Chrome installed
- __selenium/standalone-firefox__: Selenium standalone with Firefox
- __selenium/node-chrome-debug__: Selenium node with Chrome installed and runs a VNC server, needs to be connected to a Selenium Hub
- __selenium/node-firefox-debug__: Selenium node with Firefox installed and runs a VNC server, needs to be connected to a Selenium Hub

## Running the images

### Standalone Chrome and Firefox

``` bash
$ docker run -d -p 4444:4444 selenium/standalone-chrome:2.44.0
```

### Selenium Grid Hub

``` bash
$ docker run -d -p 4444:4444 --name selenium-hub selenium/hub:2.44.0
```

### Chrome and Firefox Nodes

``` bash
$ docker run -d --link selenium-hub:hub selenium/node-chrome:2.44.0
$ docker run -d --link selenium-hub:hub selenium/node-firefox:2.44.0
```

## Building the images

Ensure you have the `ubuntu:14.04` base image downloaded, this step is _optional_ since docker takes care of downloading the parent base image automatically.

``` bash
$ docker pull ubuntu:14.04
```

Clone the repo and from the project directory root you can build everything by running:

``` bash
$ VERSION=local make build
```

_Note: omitting `VERSION=local` will build the images with the current version number thus overwriting the images downloaded from dockerhub._

## Using the images

##### e.g. Spawn a container for Chrome testing:

``` bash
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:2.44.0
$ CH=$(docker run --rm --name=ch \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    selenium/node-chrome:2.44.0)
```

Note `-v /e2e/uploads:/e2e/uploads` is optional in case you are testing browser uploads on your webapp you'll probably need to share a directory for this.

I like to remove the containers after each e2e test with `--rm` since this docker container is not meant to preserve state, spawning a new one is less than 3 seconds. You need to think of your docker container as processes, not as running virtual machines if case you are familiar with vagrant.

##### e.g. Spawn a container for Firefox testing:

This command line is the same as for Chrome, remember that the selenium running container is able to launch either Chrome or Firefox, the idea around having 2 separate containers, one for each browser is for convenience plus avoid certain `:focus` issues you web app may encounter during e2e automation.

``` bash
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:2.44.0
$ FF=$(docker run --rm --name=ch \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    selenium/node-firefox:2.44.0)
```

## Debugging

In the event you wish to visually see what the browser is doing you will want to run the selenium/node-chrome-debug and selenium/node-firefox-debug images.

``` bash
$ docker run -d -P --link selenium-hub:hub selenium/node-chrome-debug:2.44.0
$ docker run -d -P --link selenium-hub:hub selenium/node-firefox-debug:2.44.0
```

You can acquire the port that the VNC server is exposed to by running:

``` bash
$ docker port <container-name|container-id> 5900
#=> 0.0.0.0:49338
```

In case you have RealVNC binary `vnc` in your path, you can always take a look, view only to avoid messing around your tests with an unintended mouse click or keyboard.

``` bash
$ ./bin/vncview 127.0.0.1:49160
```

If you are running Boot2Docker on Mac then you already have a [VNC client](http://www.davidtheexpert.com/post.php?id=5) built-in. You can connect by entering `vnc://<boot2docker-ip>:49160` in Safari or [Alfred](http://www.alfredapp.com/)

When you are prompted for the password it is __secret__. If you wish to change this then you should either change it in the `/NodeBase/Dockerfile` and build the images yourself, or you can define a docker image that derives from the posted ones which reconfigures it:

``` dockerfile
#FROM selenium/node-chrome-debug:2.44.0
#FROM selenium/node-firefox-debug:2.44.0
# Choose the FROM statement that works for you.

RUN x11vnc -storepasswd <your-password-here> /home/seluser/.vnc/passwd
```

##### Look around

``` bash
$ docker images
#=>
REPOSITORY                      TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
selenium/node-firefox           2.44.0              c7c0c99afabd        31 minutes ago      695.9 MB
selenium/node-chrome            2.44.0              c4cd17423321        31 minutes ago      796.7 MB
selenium/node-base              2.44.0              4f7c1788fe4c        32 minutes ago      584.8 MB
selenium/hub                    2.44.0              427462f54676        35 minutes ago      431.4 MB
selenium/base                   2.44.0              9126579ae96e        35 minutes ago      431.4 MB
ubuntu                          14.04               5506de2b643b        3 weeks ago         199.3 MB
```

### Troubleshooting

All output is sent to stdout so it can be inspected by running:

``` bash
$ docker logs -f <container-id|container-name>
```
