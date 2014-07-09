## Docker build to spawn selenium standalone servers with Chrome and Firefox

* selenium-server-standalone
* google-chrome-stable
* firefox (stable)
* VNC access (useful for debugging the container)
* fluxbox (lightweight window manager for X)

### 1. Build this image

```bash
sudo docker build -t="elgalu/docker-selenium:latest" .
```

### 2. Use this image

#### e.g. Spawn a container for Chrome testing:

```bash
CH=$(sudo docker run --rm --name=ch -p=127.0.0.1::4444 -p=127.0.0.1::5900 \
    -v /e2e/uploads:/opt/uploads elgalu/docker-selenium:latest)

# Obtain the selenium port you'll connect to:
docker port $CH 4444
#=> 127.0.0.1:49155

# Obtain the VNC server port in case you want to look around
docker port $CH 5900
#=> 127.0.0.1:49160

./bin/vncview 127.0.0.1:49160
```

#### e.g. Spawn a container for Firefox testing:

```bash
FF=$(sudo docker run --rm --name=ff -p=127.0.0.1::4444 -p=127.0.0.1::5900 \
    -v /e2e/uploads:/opt/uploads elgalu/docker-selenium:latest)
```
