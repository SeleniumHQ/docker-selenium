# Vaadin Testbench Docker

The project is made possible by volunteer contributors who have put in thousands of hours of their own time, and made the source code freely available under the [Apache License 2.0](https://github.com/SeleniumHQ/docker-vaadin-testbench/blob/master/LICENSE.md) and it contains the Vaadin Testbench 5.x standalone.jar which is distributed under the [CVAL 3.0](https://vaadin.com/license/cval-3.0). 

## Docker images for Vaadin Testbench Standalone Server Hub and Node configurations with Chrome and Firefox

Images included:
- __urosporo/testbench-base__: Base image which includes Java runtime and Vaadin Testbench 5.x Standalone JAR file
- __urosporo/testbench-hub__: Image for running a Grid Hub
- __urosporo/testbench-node-base__: Base image for Grid Nodes which includes a virtual desktop environment
- __urosporo/testbench-node-chrome__: Grid Node with Chrome installed, needs to be connected to a Grid Hub
- __urosporo/testbench-node-firefox__: Grid Node with Firefox installed, needs to be connected to a Grid Hub
- __urosporo/testbench-node-chrome-debug__: Grid Node with Chrome installed and runs a VNC server, needs to be connected to a Grid Hub
- __urosporo/testbench-node-firefox-debug__: Grid Node with Firefox installed and runs a VNC server, needs to be connected to a Grid Hub
- __urosporo/testbench-standalone-chrome__: Vaadin Testbench Standalone with Chrome installed
- __urosporo/testbench-standalone-firefox__: Vaadin Testbench Standalone with Firefox installed
- __urosporo/testbench-standalone-chrome-debug__: Vaadin Testbench Standalone with Chrome installed and runs a VNC server
- __urosporo/testbench-standalone-firefox-debug__: Vaadin Testbench Standalone with Firefox installed and runs a VNC server

##

## Running the images
:exclamation: When executing `docker run` for an image with Chrome or Firefox please either mount `-v /dev/shm:/dev/shm` or use the flag `--shm-size=2g` to use the host's shared memory.

Chrome
``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm urosporo/testbench-standalone-chrome:5.1.2
#OR
$ docker run -d -p 4444:4444 --shm-size=2g urosporo/testbench-standalone-chrome:5.1.2
```
Firefox
``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm urosporo/testbench-standalone-firefox:5.1.2
#OR
$ docker run -d -p 4444:4444 --shm-size 2g urosporo/testbench-standalone-firefox:5.1.2
```
This is a known workaround to avoid the browser crashing inside a docker container, here are the documented issues for
[Chrome](https://code.google.com/p/chromium/issues/detail?id=519952) and [Firefox](https://bugzilla.mozilla.org/show_bug.cgi?id=1338771#c10).
The shm size of 2gb is arbitrary but known to work well, your specific use case might need a different value, it is recommended
to tune this value according to your needs. Along the examples `-v /dev/shm:/dev/shm` will be used, but both are known to work.


### Standalone Chrome and Firefox

``` bash
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm urosporo/testbench-standalone-chrome:5.1.2
# OR
$ docker run -d -p 4444:4444 -v /dev/shm:/dev/shm urosporo/testbench-standalone-firefox:5.1.2
```

_Note: Only one standalone image can run on port_ `4444` _at a time._

To inspect visually what the browser is doing use the `standalone-chrome-debug` or `standalone-firefox-debug` images. See [Debugging](#debugging) section for details.

### Vaadin Testbench Grid Hub and Nodes
There are different ways to run the images and create a grid, check the following options.

#### Using docker networking
With this option, the hub and nodes will be created in the same network and they will recognize each other by their container name.
A docker [network](https://docs.docker.com/engine/reference/commandline/network_create/) needs to be created as a first step.

``` bash
$ docker network create grid
$ docker run -d -p 4444:4444 --net grid --name testbench-hub urosporo/testbench-hub:5.1.2
$ docker run -d --net grid -e HUB_HOST=testbench-hub -v /dev/shm:/dev/shm urosporo/testbench-node-chrome:5.1.2
$ docker run -d --net grid -e HUB_HOST=testbench-hub -v /dev/shm:/dev/shm urosporo/testbench-node-firefox:5.1.2
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
    image: urosporo/testbench-node-firefox:5.1.2
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub

  chrome:
    image: urosporo/testbench-node-chrome:5.1.2
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub

  hub:
    image: urosporo/testbench-hub:5.1.2
    ports:
      - "4444:4444"
```

##### Version 3
```yaml
# To execute this docker-compose yml file use `docker-compose -f <file_name> up`
# Add the `-d` flag at the end for detached execution
version: "3"
services:
  testbench-hub:
    image: urosporo/testbench-hub:5.1.2
    container_name: testbench-hub
    ports:
      - "4444:4444"
  chrome:
    image: urosporo/testbench-node-chrome:5.1.2
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - testbench-hub
    environment:
      - HUB_HOST=testbench-hub
      - HUB_PORT=4444
  firefox:
    image: urosporo/testbench-node-firefox:5.1.2
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - testbench-hub
    environment:
      - HUB_HOST=testbench-hub
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
   image: urosporo/testbench-hub:5.1.2
   ports:
     - "4444:4444"

  chrome:
    image: urosporo/testbench-node-chrome:5.1.2
    volumes:
      - /dev/shm:/dev/shm
    environment:
      HUB_HOST: hub
      HUB_PORT: 4444
    deploy:
        replicas: 1
    entrypoint: bash -c 'SE_OPTS="-host $$HOSTNAME" /opt/bin/entry_point.sh'

  firefox:
    image: urosporo/testbench-node-firefox:5.1.2
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
$ docker run -d -p 4444:4444 --name testbench-hub urosporo/testbench-hub:5.1.2
$ docker run -d --link testbench-hub:hub -v /dev/shm:/dev/shm urosporo/testbench-node-chrome:5.1.2
$ docker run -d --link testbench-hub:hub -v /dev/shm:/dev/shm urosporo/testbench-node-firefox:5.1.2
```

## Configuring the containers

### JAVA_OPTS Java Environment Options

You can pass `JAVA_OPTS` environment variable to java process.

``` bash
$ docker run -d -p 4444:4444 -e JAVA_OPTS=-Xmx512m --name testbench-hub urosporo/testbench-hub:5.1.2
```

### SE_OPTS Vaadin Testbench Configuration Options

You can pass `SE_OPTS` variable with additional commandline parameters for starting a hub or a node.

``` bash
$ docker run -d -p 4444:4444 -e SE_OPTS="-debug" --name testbench-hub urosporo/testbench-hub:5.1.2
```

### Vaadin Testbench Hub and Node Configuration options

For special network configurations or when the hub and the nodes are running on different machines `HUB_HOST` and `HUB_PORT`
or `REMOTE_HOST` can be used.

You can pass the `HUB_HOST` and `HUB_PORT` options to provide the hub address to a node when needed.

``` bash
# Assuming a hub was already started on the default port
$ docker run -d -e HUB_HOST=<hub_ip|hub_name> -e HUB_PORT=4444 urosporo/testbench-node-chrome:5.1.2
```

Some network topologies might prevent the hub to reach the node through the url given at registration time, `REMOTE_HOST`
can be used to supply the hub a url where the node is reachable under your specific network configuration

``` bash
# Assuming a hub was already started on the default port
$ docker run -d -p <node_port>:5555 -e HUB_HOST=<hub_ip|hub_name> -e HUB_PORT=4444 -e REMOTE_HOST="http://<node_ip|node_name>:<node_port>" urosporo/testbench-node-firefox:5.1.2
```

### Setting Screen Resolution

By default, nodes start with a screen resolution of 1360 x 1020 with a color depth of 24 bits.  These settings can be adjusted by specifying `SCREEN_WIDTH`, `SCREEN_HEIGHT` and/or `SCREEN_DEPTH` environmental variables when starting the container.

``` bash
docker run -d -e SCREEN_WIDTH=1366 -e SCREEN_HEIGHT=768 -e SCREEN_DEPTH=24 urosporo/testbench-standalone-firefox
```

### Increasing the number of browser instances/slots

By default, each image will only allow one slot per container, which is what we recommend as a best practice since all
container resources and variables will be used for that browser, and this helps to have more stable tests.

Nevertheless, if you would like to have more slots per node, this can be configured via environment variables with the
environment variable `NODE_MAX_INSTANCES`. For example, a Firefox node with 5 slots:

``` bash
# Assuming a hub was already started
$ docker run -d -e HUB_HOST=<hub_ip|hub_name> -e NODE_MAX_INSTANCES=5 urosporo/testbench-node-firefox:5.1.2
```

Don't forget to combine this with the environment variable `NODE_MAX_SESSION`, which sets the maximum amount of tests
that can run at the same time in a node. Following the previous example, if `NODE_MAX_INSTANCES=5`, then `NODE_MAX_SESSION`
should also be at least 5. Full example:

``` bash
# Assuming a hub was already started
$ docker run -d -e HUB_HOST=<hub_ip|hub_name> -e NODE_MAX_INSTANCES=5 -e NODE_MAX_SESSION=5 urosporo/testbench-node-firefox:5.1.2
```

### Running in Headless mode

Both [Firefox](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Headless_mode) and [Chrome](https://developers.google.com/web/updates/2017/04/headless-chrome) support running tests in headless mode.
When using headless mode, there's no need for the [Xvfb](https://en.wikipedia.org/wiki/Xvfb) server to be started.

To avoid starting the server you can set the `START_XVFB` environment variable to `false` (or any other value than `true`), for example:

``` bash
$ docker run -d --net grid -e HUB_HOST=testbench-hub -e START_XVFB=false -v /dev/shm:/dev/shm urosporo/testbench-node-chrome
``` 

For more information, see this Github [issue](https://github.com/SeleniumHQ/docker-selenium/issues/567).

## Using the images

##### Example: Spawn a container for testing in Chrome:

``` bash
$ docker run -d --name testbench-hub -p 4444:4444 urosporo/testbench-hub:5.1.2
$ CH=$(docker run --rm --name=ch \
    --link testbench-hub:hub -v /e2e/uploads:/e2e/uploads \
    -v /dev/shm:/dev/shm \
    urosporo/testbench-node-chrome:5.1.2)
```

_Note:_ `-v /e2e/uploads:/e2e/uploads` _is optional in case you are testing browser uploads on your web app you will probably need to share a directory for this._

##### Example: Spawn a container for testing in Firefox:

This command line is the same as for Chrome. Remember that the Vaadin Testbench running container is able to launch either Chrome or Firefox, the idea around having 2 separate containers, one for each browser is for convenience plus avoiding certain `:focus` issues your web app may encounter during end-to-end test automation.

``` bash
$ docker run -d --name testbench-hub -p 4444:4444 urosporo/testbench-hub:5.1.2
$ FF=$(docker run --rm --name=fx \
    --link testbench-hub:hub -v /e2e/uploads:/e2e/uploads \
    -v /dev/shm:/dev/shm \
    urosporo/testbench-node-firefox:5.1.2)
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
$ docker run -d -p 4444:4444 --net grid --name testbench-hub \
    --health-cmd='/opt/bin/check-grid.sh --host 0.0.0.0 --port 4444' \
    --health-interval=15s --health-timeout=30s --health-retries=5 \
    urosporo/testbench-hub:5.1.2
$ docker run -d --net grid -e HUB_HOST=testbench-hub -v /dev/shm:/dev/shm urosporo/testbench-node-chrome:5.1.2
$ docker run -d --net grid -e HUB_HOST=testbench-hub -v /dev/shm:/dev/shm urosporo/testbench-node-firefox:5.1.2
```
**Note:** The `\` line delimiter won't work on Windows based terminals, try either `^` or a backtick.

The container health status can be checked by doing `docker ps` and verifying the `(healthy)|(unhealthy)` status or by
inspecting it in the following way:

```bash
$ docker inspect --format='{{json .State.Health.Status}}' testbench-hub
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

>&2 echo "Vaadin Testbench Grid is up - executing tests"
exec $cmd
```
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
$ docker run -d -P -p <port4VNC>:5900 --link testbench-hub:hub -v /dev/shm:/dev/shm urosporo/testbench-node-chrome-debug:5.1.2
$ docker run -d -P -p <port4VNC>:5900 --link testbench-hub:hub -v /dev/shm:/dev/shm urosporo/testbench-node-firefox-debug:5.1.2
```
e.g.:
``` bash
$ docker run -d -P -p 5900:5900 --link testbench-hub:hub -v /dev/shm:/dev/shm urosporo/testbench-node-chrome-debug:5.1.2
$ docker run -d -P -p 5901:5900 --link testbench-hub:hub -v /dev/shm:/dev/shm urosporo/testbench-node-firefox-debug:5.1.2
```
to connect to the Chrome node on 5900 and the Firefox node on 5901 (assuming those node are free, and reachable).

And for standalone:
``` bash
$ docker run -d -p 4444:4444 -p <port4VNC>:5900 -v /dev/shm:/dev/shm urosporo/testbench-standalone-chrome-debug:5.1.2
# OR
$ docker run -d -p 4444:4444 -p <port4VNC>:5900 -v /dev/shm:/dev/shm urosporo/testbench-standalone-firefox-debug:5.1.2
```
or
``` bash
$ docker run -d -p 4444:4444 -p 5900:5900 -v /dev/shm:/dev/shm urosporo/testbench-standalone-chrome-debug:5.1.2
# OR
$ docker run -d -p 4444:4444 -p 5901:5900 -v /dev/shm:/dev/shm urosporo/testbench-standalone-firefox-debug:5.1.2
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
#FROM urosporo/testbench-node-chrome-debug:5.1.2
#FROM urosporo/testbench-node-firefox-debug:5.1.2
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

If you see the following Vaadin Testbench exceptions:

`Message: invalid argument: can't kill an exited process`

or

`Message: unknown error: Chrome failed to start: exited abnormally`

The reason _might_ be that you've set the `START_XVFB` environment variable to "false", but forgot to actually run Firefox or Chrome (respectively) in headless mode.
