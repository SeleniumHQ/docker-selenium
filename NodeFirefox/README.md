## Building NodeFirefox and StandaloneFirefox for ARM64

I haven't located a geckdriver binary for Debian, so we'll build it from source. Unfortunately, the build step cannot yet be automated. Trying to run it as part of a docker build or even using docker exec causes the build to fail for reasons unknown to me.

As a result, I split the build process into various steps:

### Step 0

Make sure the local-seleniarm/base:latest and local-seleniarm/node-base:latest have been built using the command that builds all of the other images. If you haven't yet done this, run this from the root of the repository.

```
$ sh build.sh
```

Before proceeding, verify that local-seleniarm/base:latest and local-seleniarm/node-base:latest exist by using `docker image ls`.


### Step 1

In Step 1, we'll build the geckodriver. The geckodriver must be built specifically for Debian and specifically for the ARM64 platform, and we'll use an intermediate, throwaway Debian container to automatically setup the build environment by installing all of the needed dependencies. Once the build environment is setup, we'll need to manually run the compile step. To start this process, run the following command from the NodeFirefox working directory:

```
$ cd NodeFirefox
$ sh build-step-1.sh   # This installs dependencies and drops you into a container bash shell
```

Once the dependencies are installed, we'll automatically drop into the container's shell in the `/opt/geckodriver` directory. At this stage, run this command:

```
$ sh build-geckodriver-arm64.sh
```

This uses Rust and cargo to build geckodriver. Afterwards, the script copies the binary to `/media/share` on the host. The script then moves it to the NodeFirefox directory where it will be copied into the NodeFirefox image in the next step.  Once built, exit the container:

```
$ exit
```

Before proceeding to the next step, verify the geckodriver binary is inside the NodeFirefox folder.


### Step 2

At this stage, we're ready to build both NodeFirefox and StandaloneFirefox. To build these images, run the following command:

```
$ sh build-step-2.sh
```

After this completes, we see all of the container images, both with the latest tag and today's date, using `docker image ls`.


## Running the StandaloneFirefox image

```
$ docker run --rm -it --shm-size 3g -p 4444:4444 -p 5900:5900 -p 7900:7900 local-seleniarm/standalone-firefox:latest
```

As with the x86_64 images from upstream, this also includes noVNC on port 7900, which we can access via http://localhost:7900
