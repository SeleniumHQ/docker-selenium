# Vaadin Testbench Grid Standalone - Firefox Debug

_This image is only intended for development purposes!_ Runs a Vaadin Testbench Grid Standalone with a VNC Server to allow you to visually see the browser being automated.


## Dockerfile

[`urosporo/testbench-standalone-firefox-debug` Dockerfile](https://github.com/urosporo/docker-vaadin-testbench/blob/master/StandaloneFirefoxDebug/Dockerfile)

## How to use this image


```
$ docker run -d -p 4444:4444 -p 5900:5900 -v /dev/shm:/dev/shm urosporo/testbench-standalone-firefox-debug
```

You can acquire the port that the VNC server is exposed to by running:
(Assuming that we mapped the ports like this: 49338:5900)
``` bash
$ docker port <container-name|container-id> 5900
#=> 0.0.0.0:49338
```

In case you have [RealVNC](https://www.realvnc.com/) binary `vnc` in your path, you can always take a look, view only to avoid messing around your tests with an unintended mouse click or keyboard interrupt:
``` bash
$ ./bin/vncview 127.0.0.1:49338
```

If you are running Boot2Docker on Mac then you already have a [VNC client](http://www.davidtheexpert.com/post.php?id=5) built-in. You can connect by entering `vnc://<boot2docker-ip>:49160` in Safari or [Alfred](http://www.alfredapp.com/)

## What is Vaadin Testbench?
_Vaadin Testbench is based on Selenium and automates browsers to test Vaadin-based applications._ That's it! What you do with that power is entirely up to you. Primarily, it is for automating web applications for testing purposes, but is certainly not limited to just that. Boring web-based administration tasks can (and should!) also be automated as well.

Selenium (Vaadin Testbench) has the support of some of the largest browser vendors who have taken (or are taking) steps to make Selenium a native part of their browser. It is also the core technology in countless other browser automation tools, APIs and frameworks.

See the Vaadin Testbench [site](https://vaadin.com/docs/v8/testbench/testbench-overview.html) for documation on usage within your test code.

## License

View [license information](https://github.com/urosporo/docker-vaadin-testbench/blob/master/LICENSE.md) for the software contained in this image.

## Getting Help

### User Group

The first place where people ask for help about Selenium is the [Official User Group](https://groups.google.com/forum/#!forum/selenium-users). Here, you'll find that most of the time, someone already found the problem you are facing right now, and usually reached the solution for which you are looking.

_Note: Please make sure to search the group before asking for something. Your question likely won't get answered if it was previously answered in another discussion!_

### Issues

If you have any problems with or questions about this image, please contact us through a [Github issue](https://github.com/urosporo/docker-vaadin-testbench/issues). If you have any problems with or questions about Vaadin Testbench, please contact Vaadin through Vaadin's [Bug Tracker](https://github.com/vaadin/testbench/issues). If you have any problems with or questions about Selenium, please contact Selenium through Selenium's [Bug Tracker](https://github.com/SeleniumHQ/selenium/issues).
