USER := elgalu
VERSION := 2.44.0

all: hub chrome firefox full

base:
	cd ./Base && docker build -t $(USER)/selenium-base:$(VERSION) .

hub: base
	cd ./Hub && docker build -t $(USER)/selenium-hub:$(VERSION) .

nodebase: base
	cd ./NodeBase && docker build -t $(USER)/selenium-node-base:$(VERSION) .

chrome: nodebase
	rm -rf tmp
	mkdir -p tmp/build/chrome
	cp build/Dockerfile tmp/Dockerfile
	cp build/install.sh tmp/build/install.sh
	cp -pR build/chrome tmp/build/
	cd ./tmp && docker build -t $(USER)/selenium-node-chrome:$(VERSION) .

firefox: nodebase
	rm -rf tmp
	mkdir -p tmp/build/firefox
	cp build/Dockerfile tmp/Dockerfile
	cp build/install.sh tmp/build/install.sh
	cp -pR build/firefox tmp/build/
	cd ./tmp && docker build -t $(USER)/selenium-node-firefox:$(VERSION) .

full: nodebase
	rm -rf tmp
	mkdir -p tmp/build/
	cp build/Dockerfile tmp/Dockerfile
	cp -pR build/ tmp/build/
	cp -pR Hub/etc/ tmp/build/full/etc/
	cd ./tmp && docker build -t $(USER)/selenium-full:$(VERSION) .

.PHONY: all base hub nodebase
