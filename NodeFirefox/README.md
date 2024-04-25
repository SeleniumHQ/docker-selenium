## Building Multi-arch NodeFirefox and StandaloneFirefox

There are two Dockerfiles in NodeFirefox. `Dockerfile` is from the upstream repository for building the standard, official amd64 images. To build `seleniarm/node-firefox` for arm64 or armv7l (or possibly amd64 as well), we use the `Dockerfile.multi-arch` file.

The easiest way to build the image is to use `make`. See examples below:


**To build node/firefox for arm64:**

```
$ NAME=local-seleniarm VERSION=4.5.0 BUILD_DATE=$(date '+%Y%m%d') PLATFORMS=linux/arm64 BUILD_ARGS=--load make firefox_multi
```

**To build standalone/firefox for arm64:**

```
$ NAME=local-seleniarm VERSION=4.5.0 BUILD_DATE=$(date '+%Y%m%d') PLATFORMS=linux/arm64 BUILD_ARGS=--load make standalone_firefox_multi
```

NOTE: Replace PLATFORMS environment variable with `linux/arm/v7` for armv7l/armhf, or `linux/amd64` for amd64.

## Running the standalone image

```
$ docker run --rm -it --shm-size 2g -p 4444:4444 -p 5900:5900 -p 7900:7900 local-seleniarm/standalone-firefox:latest
```

As with the x86_64 images from upstream, this also includes noVNC on port 7900, which we can access via http://localhost:7900
