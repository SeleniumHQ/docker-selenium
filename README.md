## Docker images for Selenium Standalone Server Hub and Node configurations with Chrome and Firefox
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/elgalu/docker-selenium?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Images included:

- __elgalu/selenium-base__: Base image which includes Java runtime and Selenium jar
- __elgalu/selenium-hub__: Image for running a Selenium Grid Hub
- __elgalu/selenium-node-base__: Base image for Selenium Nodes which includes a virtual desktop environment and VNC support
- __elgalu/selenium-node-chrome__: Selenium node with Chrome installed, needs to be connected to a Selenium Hub
- __elgalu/selenium-node-firefox__: Selenium node with Firefox installed, needs to be connected to a Selenium Hub
- __elgalu/selenium-full__: Self contained Selenium Hub and Node combined configuration with both Chrome and Firefox

## Running the images

### Selenium Grid Hub

``` bash
$ docker run -d -p 4444:4444 -p 5900:5900 --name selenium-hub elgalu/selenium-hub:2.44.0
```

### Chrome and Firefox Nodes

``` bash
$ docker run -d --link selenium-hub:hub elgalu/selenium-node-chrome:2.44.0
$ docker run -d --link selenium-hub:hub elgalu/selenium-node-firefox:2.44.0
```

### Self contained Selenium container

``` bash
$ docker run -d -p 4444:4444 -p 5900:5900 elgalu/selenium-full:2.44.0
```

## Building the images

Ensure you have the `phusion/baseimage:0.9.15` base image downloaded, this step is _optional_ since docker takes care of downloading the parent base image automatically.

``` bash
$ docker pull phusion/baseimage:0.9.15
```

Clone the repo and from the project directory root you can build everything by running:

``` bash
$ VERSION=local make build
```

_Note: omitting `VERSION=local` will build the images with the current version number thus overwriting the images downloaded from dockerhub._

## Using the images

##### e.g. Spawn a container for Chrome testing:

``` bash
$ docker run -d --name selenium-hub -p=127.0.0.1::4444 elgalu/selenium-hub:2.44.0
$ CH=$(docker run --rm --name=ch -p=127.0.0.1::5900 \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    elgalu/selenium-node-chrome:2.44.0)
```

-- or --

``` bash
$ CH=$(docker run --rm --name=ch -p=127.0.0.1::4444 -p=127.0.0.1::5900 \
    -v /e2e/uploads:/e2e/uploads elgalu/selenium-full:2.44.0)
```

Note `-v /e2e/uploads:/e2e/uploads` is optional in case you are testing browser uploads on your webapp you'll probably need to share a directory for this.

The `127.0.0.1::` part is to avoid binding to all network interfaces, most of the time you don't need to expose the docker container like that so just *localhost* for now.

I like to remove the containers after each e2e test with `--rm` since this docker container is not meant to preserve state, spawning a new one is less than 3 seconds. You need to think of your docker container as processes, not as running virtual machines if case you are familiar with vagrant.

A dynamic port will be binded to the container ones, i.e.

When you send your capabilities request for chrome be sure in include the `--no-sandbox` argument to be used when launching Chrome, for example:

```
options = webdriver.ChromeOptions()
options.add_argument("--no-sandbox")
driver = webdriver.Remote(command_executor='http://127.0.0.1:4444/wd/hub',desired_capabilities=options.to_capabilities())
driver.get("http://www.python.org")
print(driver.title)
```

``` bash
# Obtain the selenium port you'll connect to:
docker port selenium-hub 4444
# -- or --
docker port $CH 4444
#=> 127.0.0.1:49155

# Obtain the VNC server port in case you want to look around
docker port $CH 5900
#=> 127.0.0.1:49160
```

##### e.g. Spawn a container for Firefox testing:

This command line is the same as for Chrome, remember that the selenium running container is able to launch either Chrome or Firefox, the idea around having 2 separate containers, one for each browser is for convenience plus avoid certain `:focus` issues you web app may encounter during e2e automation.

``` bash
$ docker run -d --name selenium-hub -p=127.0.0.1::4444 elgalu/selenium-hub:2.44.0
$ FF=$(docker run --rm --name=ch -p=127.0.0.1::5900 \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    elgalu/selenium-node-firefox:2.44.0)
```

-- or --

``` bash
$ FF=$(docker run --rm --name=ch -p=127.0.0.1::4444 -p=127.0.0.1::5900 \
    -v /e2e/uploads:/e2e/uploads elgalu/selenium-full:2.44.0)
```

## VNC Connection

In case you have RealVNC binary `vnc` in your path, you can always take a look, view only to avoid messing around your tests with an unintended mouse click or keyboard.

``` bash
$ ./bin/vncview 127.0.0.1:49160
```

If you are running Boot2Docker on Mac then you already have a [VNC client](http://www.davidtheexpert.com/post.php?id=5) built-in. You can connect by entering `vnc://<boot2docker-ip>:49160` in Safari or [Alfred](http://www.alfredapp.com/)

When you are prompted for the password it is __secret__. If you wish to change this then you should either change it in the `/NodeBase/Dockerfile` and build the images yourself, or you can define a docker image that derives from the posted ones which reconfigures it:

``` dockerfile
FROM elgalu/selenium-node-base:2.44.0
#FROM elgalu/selenium-node-chrome:2.44.0
#FROM elgalu/selenium-node-firefox:2.44.0
#FROM elgalu/selenium-full:2.44.0
# Choose the FROM statement that works for you.

RUN x11vnc -storepasswd <your-password-here> /home/seluser/.vnc/passwd
```

##### Look around

``` bash
$ docker images
#=>
REPOSITORY                      TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
elgalu/selenium-full            2.44.0              68e369e3141e        30 minutes ago      886.3 MB
elgalu/selenium-node-firefox    2.44.0              c7c0c99afabd        31 minutes ago      695.9 MB
elgalu/selenium-node-chrome     2.44.0              c4cd17423321        31 minutes ago      796.7 MB
elgalu/selenium-node-base       2.44.0              4f7c1788fe4c        32 minutes ago      584.8 MB
elgalu/selenium-hub             2.44.0              427462f54676        35 minutes ago      431.4 MB
elgalu/selenium-base            2.44.0              9126579ae96e        35 minutes ago      431.4 MB
phusion/baseimage               0.9.15              cf39b476aeec        4 weeks ago         289.4 MB
```

### Troubleshooting

All output is sent to stdout so it can be inspected by running:

``` bash
$ docker logs -f <container-id|container-name>
```

The containers leave a few log files in addition to stdout output to see what happened:

``` bash
/tmp/Xvfb_headless.log
/tmp/fluxbox_manager.log
/tmp/x11vnc_forever.log
/tmp/sel-hub.log
/tmp/sel-node.log
```
