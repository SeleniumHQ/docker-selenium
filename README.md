# Selenium Docker

The project is made possible by volunteer contributors who have put in thousands of hours of their own time, and made the source code freely available under the [Apache License 2.0](https://github.com/SeleniumHQ/docker-selenium/blob/master/LICENSE.md).

## Community

### [SeleniumHQ Slack](https://seleniumhq.herokuapp.com/)

### IRC (&#35;selenium at Freenode)

## Docker images for Selenium Standalone Server Hub and Node configurations with Chrome and Firefox
[Travis CI](https://travis-ci.org/SeleniumHQ/docker-selenium)

Images included:
- __selenium/base__: Base image which includes Java runtime and Selenium Server JAR file
- __selenium/hub__: Image for running a Grid Hub
- __selenium/node-base__: Base image for Grid Nodes which includes a virtual desktop environment
- __selenium/node-chrome__: Grid Node with Chrome installed, needs to be connected to a Grid Hub
- __selenium/node-firefox__: Grid Node with Firefox installed, needs to be connected to a Grid Hub
- __selenium/node-chrome-debug__: Grid Node with Chrome installed and runs a VNC server, needs to be connected to a Grid Hub
- __selenium/node-firefox-debug__: Grid Node with Firefox installed and runs a VNC server, needs to be connected to a Grid Hub
- __selenium/standalone-chrome__: Selenium Standalone with Chrome installed
- __selenium/standalone-firefox__: Selenium Standalone with Firefox installed
- __selenium/standalone-chrome-debug__: Selenium Standalone with Chrome installed and runs a VNC server
- __selenium/standalone-firefox-debug__: Selenium Standalone with Firefox installed and runs a VNC server

##

## Running the images
:exclamation: When executing `docker run` for an image with Chrome or Firefox please either mount `-v /dev/shm:/dev/shm` or use the flag `--shm-size=2g` to use the host's shared memory.

:exclamation: In general, use a tag with an element suffix to pin a specific browser version. See [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

Chrome
``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome:3.141.59-selenium
#OR
$ docker run -d -p 4444:4444 --shm-size=2g selenium/standalone-chrome:3.141.59-selenium
```
Firefox
``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-firefox:3.141.59-selenium
#OR
$ docker run -d -p 4444:4444 --shm-size 2g selenium/standalone-firefox:3.141.59-selenium
```
This is a known workaround to avoid the browser crashing inside a docker container, here are the documented issues for
[Chrome](https://code.google.com/p/chromium/issues/detail?id=519952) and [Firefox](https://bugzilla.mozilla.org/show_bug.cgi?id=1338771#c10).
The shm size of 2gb is arbitrary but known to work well, your specific use case might need a different value, it is recommended
to tune this value according to your needs. Along the examples `-v /dev/shm:/dev/shm` will be used, but both are known to work.


### Standalone Chrome and Firefox

``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome:3.141.59-selenium
# OR
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-firefox:3.141.59-selenium
```

_Note: Only one standalone image can run on port_ `4444` _at a time._

To inspect visually what the browser is doing use the `standalone-chrome-debug` or `standalone-firefox-debug` images. See [Debugging](#debugging) section for details.

### Selenium Grid Hub and Nodes
There are different ways to run the images and create a grid, check the following options.

#### Using docker networking
With this option, the hub and nodes will be created in the same network and they will recognize each other by their container name.
A docker [network](https://docs.docker.com/engine/reference/commandline/network_create/) needs to be created as a first step.

``` bash
$ docker network create grid
$ docker run -d -p 4444:4444 --net grid --name selenium-hub selenium/hub:3.141.59-selenium
$ docker run -d --net grid -e HUB_HOST=selenium-hub -v /dev/shm:/dev/shm selenium/node-chrome:3.141.59-selenium
$ docker run -d --net grid -e HUB_HOST=selenium-hub -v /dev/shm:/dev/shm selenium/node-firefox:3.141.59-selenium
```

When you are done using the grid and the containers have exited, the network can be removed with the following command:

``` bash
# Remove all unused networks
$ docker network prune
# OR
# Removes the grid network
$ docker network rm grid
```

#### Via docker-compose
The most simple way to start a grid is with [docker-compose](https://docs.docker.com/compose/overview/), use the following
snippet as your `docker-compose.yaml`, save it locally and in the same folder run `docker-compose up`.

##### Version 2
```yaml
# To execute this docker-compose yml file use `docker-compose -f <file_name> up`
# Add the `-d` flag at the end for detached execution
version: '2'
services:
  firefox:
    image: selenium/node-firefox:3.141.59-selenium
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub

  chrome:
    image: selenium/node-chrome:3.141.59-selenium
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub

  hub:
    image: selenium/hub:3.141.59-selenium
    ports:
      - "4444:4444"
```

##### Version 3
```yaml
# To execute this docker-compose yml file use `docker-compose -f <file_name> up`
# Add the `-d` flag at the end for detached execution
version: "3"
services:
  selenium-hub:
    image: selenium/hub:3.141.59-selenium
    container_name: selenium-hub
    ports:
      - "4444:4444"
  chrome:
    image: selenium/node-chrome:3.141.59-selenium
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - selenium-hub
    environment:
      - HUB_HOST=selenium-hub
      - HUB_PORT=4444
  firefox:
    image: selenium/node-firefox:3.141.59-selenium
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - selenium-hub
    environment:
      - HUB_HOST=selenium-hub
      - HUB_PORT=4444
```

To stop the grid and cleanup the created containers, run `docker-compose down`.

##### Version 3 with Swarm support
```yaml
# To start Docker in Swarm mode, you need to run `docker swarm init`
# To deploy the Grid, `docker stack deploy -c docker-compose.yml grid`
# Stop with `docker stack rm grid`

version: '3.7'

services:
  hub:
   image: selenium/hub:3.141.59-selenium
   ports:
     - "4444:4444"

  chrome:
    image: selenium/node-chrome:3.141.59-selenium
    volumes:
      - /dev/shm:/dev/shm
    environment:
      HUB_HOST: hub
      HUB_PORT: 4444
    deploy:
        replicas: 1
    entrypoint: bash -c 'SE_OPTS="-host $$HOSTNAME" /opt/bin/entry_point.sh'

  firefox:
    image: selenium/node-firefox:3.141.59-selenium
    volumes:
      - /dev/shm:/dev/shm
    environment:
      HUB_HOST: hub
      HUB_PORT: 4444
    deploy:
        replicas: 1
    entrypoint: bash -c 'SE_OPTS="-host $$HOSTNAME" /opt/bin/entry_point.sh'
```

#### Using `--link`
This option can be used for a single host scenario (hub and nodes running in a single machine), but it is not recommended
for longer term usage since this is a docker [legacy feature](https://docs.docker.com/compose/compose-file/#links).
It could serve you as an option for a proof of concept, and for simplicity it is used in the examples shown from now on.

``` bash
$ docker run -d -p 4444:4444 --name selenium-hub selenium/hub:3.141.59-selenium
$ docker run -d --link selenium-hub:hub -v /dev/shm:/dev/shm selenium/node-chrome:3.141.59-selenium
$ docker run -d --link selenium-hub:hub -v /dev/shm:/dev/shm selenium/node-firefox:3.141.59-selenium
```

### Deploying to Kubernetes

Check out [the Kubernetes examples](https://github.com/kubernetes/examples/tree/master/staging/selenium)
on how to deploy selenium hub and nodes on a Kubernetes cluster.

## Configuring the containers

### JAVA_OPTS Java Environment Options

You can pass `JAVA_OPTS` environment variable to java process.

``` bash
$ docker run -d -p 4444:4444 -e JAVA_OPTS=-Xmx512m --name selenium-hub selenium/hub:3.141.59-selenium
```

### SE_OPTS Selenium Configuration Options

You can pass `SE_OPTS` variable with additional commandline parameters for starting a hub or a node.

``` bash
$ docker run -d -p 4444:4444 -e SE_OPTS="-debug" --name selenium-hub selenium/hub:3.141.59-selenium
```

### JAVA_CLASSPATH Java classpath

By default, `CLASSPATH` for Java is `/opt/selenium/*:.` but you can overwrite it with yours using `JAVA_CLASSPATH`. This is useful when you want to use your own JAR files. Note that `/opt/selenium/*` always needs to be included because the Selenium JAR file is in the directory.

```bash
$ docker run -d -p 4444:4444 -v $(pwd):/mnt -e JAVA_CLASSPATH="/mnt/*:/opt/selenium/*:." -e SE_OPTS="-servlets com.example.your.AwesomeServlet" --name selenium-hub selenium/hub:3.141.59-selenium
```

### Selenium Hub and Node Configuration options

For special network configurations or when the hub and the nodes are running on different machines `HUB_HOST` and `HUB_PORT`
or `REMOTE_HOST` can be used.

You can pass the `HUB_HOST` and `HUB_PORT` options to provide the hub address to a node when needed.

``` bash
# Assuming a hub was already started on the default port
$ docker run -d -e HUB_HOST=<hub_ip|hub_name> -e HUB_PORT=4444 selenium/node-chrome:3.141.59-selenium
```

Some network topologies might prevent the hub to reach the node through the url given at registration time, `REMOTE_HOST`
can be used to supply the hub a url where the node is reachable under your specific network configuration

``` bash
# Assuming a hub was already started on the default port
$ docker run -d -p <node_port>:5555 -e HUB_HOST=<hub_ip|hub_name> -e HUB_PORT=4444 -e REMOTE_HOST="http://<node_ip|node_name>:<node_port>" selenium/node-firefox:3.141.59-selenium
```

### Setting Screen Resolution

By default, nodes start with a screen resolution of 1360 x 1020 with a color depth of 24 bits and a dpi of 96. These settings can be adjusted by specifying `SCREEN_WIDTH`, `SCREEN_HEIGHT`, `SCREEN_DEPTH`, and/or `SCREEN_DPI` environmental variables when starting the container.

``` bash
docker run -d -e SCREEN_WIDTH=1366 -e SCREEN_HEIGHT=768 -e SCREEN_DEPTH=24 -e SCREEN_DPI=74 selenium/standalone-firefox
```

Bear in mind that in non-debug images, the maximize window command won't work. You can use the resize window command
instead. Also, some browser drivers allow specifying window size in capabilities.

### Increasing the number of browser instances/slots

By default, each image will only allow one slot per container, which is what we recommend as a best practice since all
container resources and variables will be used for that browser, and this helps to have more stable tests.

Nevertheless, if you would like to have more slots per node, this can be configured via environment variables with the
environment variable `NODE_MAX_INSTANCES`. For example, a Firefox node with 5 slots:

``` bash
# Assuming a hub was already started
$ docker run -d -e HUB_HOST=<hub_ip|hub_name> -e NODE_MAX_INSTANCES=5 selenium/node-firefox:3.141.59-selenium
```

Don't forget to combine this with the environment variable `NODE_MAX_SESSION`, which sets the maximum amount of tests
that can run at the same time in a node. Following the previous example, if `NODE_MAX_INSTANCES=5`, then `NODE_MAX_SESSION`
should also be at least 5. Full example:

``` bash
# Assuming a hub was already started
$ docker run -d -e HUB_HOST=<hub_ip|hub_name> -e NODE_MAX_INSTANCES=5 -e NODE_MAX_SESSION=5 selenium/node-firefox:3.141.59-selenium
```

### Running in Headless mode

Both [Firefox](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Headless_mode) and [Chrome](https://developers.google.com/web/updates/2017/04/headless-chrome) support running tests in headless mode.
When using headless mode, there's no need for the [Xvfb](https://en.wikipedia.org/wiki/Xvfb) server to be started.

To avoid starting the server you can set the `START_XVFB` environment variable to `false` (or any other value than `true`), for example:

``` bash
$ docker run -d --net grid -e HUB_HOST=selenium-hub -e START_XVFB=false -v /dev/shm:/dev/shm selenium/node-chrome
```

For more information, see this Github [issue](https://github.com/SeleniumHQ/docker-selenium/issues/567).

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
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:3.141.59-selenium
$ CH=$(docker run --rm --name=ch \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    -v /dev/shm:/dev/shm \
    selenium/node-chrome:3.141.59-selenium)
```

_Note:_ `-v /e2e/uploads:/e2e/uploads` _is optional in case you are testing browser uploads on your web app you will probably need to share a directory for this._

##### Example: Spawn a container for testing in Firefox:

This command line is the same as for Chrome. Remember that the Selenium running container is able to launch either Chrome or Firefox, the idea around having 2 separate containers, one for each browser is for convenience plus avoiding certain `:focus` issues your web app may encounter during end-to-end test automation.

``` bash
$ docker run -d --name selenium-hub -p 4444:4444 selenium/hub:3.141.59-selenium
$ FF=$(docker run --rm --name=fx \
    --link selenium-hub:hub -v /e2e/uploads:/e2e/uploads \
    -v /dev/shm:/dev/shm \
    selenium/node-firefox:3.141.59-selenium)
```

_Note: Since a Docker container is not meant to preserve state and spawning a new one takes less than 3 seconds you will likely want to remove containers after each end-to-end test with_ `--rm` _command. You need to think of your Docker containers as single processes, not as running virtual machines, in case you are familiar with [Vagrant](https://www.vagrantup.com/)._

## Waiting for the Grid to be ready

It is a good practice to check first if the Grid is up and ready to receive requests, this can be done by checking the `/wd/hub/status` endpoint.

A Grid that is ready, composed by a hub and a node, could look like this:

```json
{
  "status": 0,
  "value": {
    "ready": true,
    "message": "Hub has capacity",
    "build": {
      "revision": "aacccce0",
      "time": "2018-08-02T20:13:22.693Z",
      "version": "3.14.0"
    },
    "os": {
      "arch": "amd64",
      "name": "Linux",
      "version": "4.9.93-linuxkit-aufs"
    },
    "java": {
      "version": "1.8.0_181"
    }
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
$ docker run -d -p 4444:4444 --net grid --name selenium-hub \
    --health-cmd='/opt/bin/check-grid.sh --host 0.0.0.0 --port 4444' \
    --health-interval=15s --health-timeout=30s --health-retries=5 \
    selenium/hub:3.141.59-selenium
$ docker run -d --net grid -e HUB_HOST=selenium-hub -v /dev/shm:/dev/shm selenium/node-chrome:3.141.59-selenium
$ docker run -d --net grid -e HUB_HOST=selenium-hub -v /dev/shm:/dev/shm selenium/node-firefox:3.141.59-selenium
```
**Note:** The `\` line delimiter won't work on Windows based terminals, try either `^` or a backtick.

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

```bash
#!/bin/bash
# wait-for-grid.sh

set -e

cmd="$@"

while ! curl -sSL "http://localhost:4444/wd/hub/status" 2>&1 \
        | jq -r '.value.ready' 2>&1 | grep "true" >/dev/null; do
    echo 'Waiting for the Grid'
    sleep 1
done

>&2 echo "Selenium Grid is up - executing tests"
exec $cmd
```
> Will require `jq` installed via `apt-get`, else the script will keep printing `Waiting` without completing the execution.

**Note:** If needed, replace `localhost` and `4444` for the correct values in your environment. Also, this script is polling indefinitely, you might want
to tweak it and establish a timeout.

Let's say that the normal command to execute your tests is `mvn clean test`. Here is a way to use the above script and execute your tests:

```bash
$ ./wait-for-grid.sh mvn clean test
```

Like this, the script will poll until the Grid is ready, and then your tests will start.

## Debugging

In the event you wish to visually see what the browser is doing you will want to run the `debug` variant of node or standalone images. A VNC server will run on port 5900. You are free to map that to any free external port that you wish. Keep in mind that you will only be able to run one node per port so if you wish to include a second node, or more, you will have to use different ports, the 5900 as the internal port will have to remain the same though as thats the VNC service on the node. The second example below shows how to run multiple nodes and with different VNC ports open:
``` bash
$ docker run -d -P -p <port4VNC>:5900 --link selenium-hub:hub -v /dev/shm:/dev/shm selenium/node-chrome-debug:3.141.59-selenium
$ docker run -d -P -p <port4VNC>:5900 --link selenium-hub:hub -v /dev/shm:/dev/shm selenium/node-firefox-debug:3.141.59-selenium
```
e.g.:
``` bash
$ docker run -d -P -p 5900:5900 --link selenium-hub:hub -v /dev/shm:/dev/shm selenium/node-chrome-debug:3.141.59-selenium
$ docker run -d -P -p 5901:5900 --link selenium-hub:hub -v /dev/shm:/dev/shm selenium/node-firefox-debug:3.141.59-selenium
```
to connect to the Chrome node on 5900 and the Firefox node on 5901 (assuming those node are free, and reachable).

And for standalone:
``` bash
$ docker run -d -p 4444:4444 -p <port4VNC>:5900 -v /dev/shm:/dev/shm selenium/standalone-chrome-debug:3.141.59-selenium
# OR
$ docker run -d -p 4444:4444 -p <port4VNC>:5900 -v /dev/shm:/dev/shm selenium/standalone-firefox-debug:3.141.59-selenium
```
or
``` bash
$ docker run -d -p 4444:4444 -p 5900:5900 -v /dev/shm:/dev/shm selenium/standalone-chrome-debug:3.141.59-selenium
# OR
$ docker run -d -p 4444:4444 -p 5901:5900 -v /dev/shm:/dev/shm selenium/standalone-firefox-debug:3.141.59-selenium
```

You can acquire the port that the VNC server is exposed to by running:
(Assuming that we mapped the ports like this: 49338:5900)
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
#FROM selenium/node-chrome-debug:3.141.59-selenium
#FROM selenium/node-firefox-debug:3.141.59-selenium
#Choose the FROM statement that works for you.

RUN x11vnc -storepasswd <your-password-here> /home/seluser/.vnc/passwd
```

If you want to run VNC without password authentication you can set the environment variable `VNC_NO_PASSWORD=1`.

### Troubleshooting

All output is sent to stdout so it can be inspected by running:
``` bash
$ docker logs -f <container-id|container-name>
```

You can turn on debugging by passing environment variable to the hub and the nodes containers:
```
GRID_DEBUG=true
```

#### Headless

If you see the following selenium exceptions:

`Message: invalid argument: can't kill an exited process`

or

`Message: unknown error: Chrome failed to start: exited abnormally`

The reason _might_ be that you've set the `START_XVFB` environment variable to "false", but forgot to actually run Firefox or Chrome (respectively) in headless mode.
