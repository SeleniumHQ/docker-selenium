NAME := selenium
VERSION := $(or $(VERSION),$(VERSION),'2.44.0')
PLATFORM := $(shell uname -s)

all: hub chrome firefox chromedebug firefoxdebug standalone_chrome standalone_firefox

build: all

ci: build test

base:
	cd ./Base && docker build -t $(NAME)/base:$(VERSION) .

hub: base
	cd ./Hub && docker build -t $(NAME)/hub:$(VERSION) .

nodebase: base
	cd ./NodeBase && docker build -t $(NAME)/node-base:$(VERSION) .

chrome: nodebase
	cd ./NodeChrome && docker build -t $(NAME)/node-chrome:$(VERSION) .

firefox: nodebase
	cd ./NodeFirefox && docker build -t $(NAME)/node-firefox:$(VERSION) .

generate_standalone_firefox:
	cd ./Standalone && ./generate.sh StandaloneFirefox node-firefox Firefox $(VERSION)

standalone_firefox: generate_standalone_firefox firefox
	cd ./StandaloneFirefox && docker build -t $(NAME)/standalone-firefox:$(VERSION) .

generate_standalone_chrome:
	cd ./Standalone && ./generate.sh StandaloneChrome node-chrome Chrome $(VERSION)

standalone_chrome: generate_standalone_chrome chrome
	cd ./StandaloneChrome && docker build -t $(NAME)/standalone-chrome:$(VERSION) .

generate_chromedebug:
	cd ./NodeDebug && ./generate.sh NodeChromeDebug node-chrome Chrome $(VERSION)

chromedebug: generate_chromedebug chrome
	cd ./NodeChromeDebug && docker build -t $(NAME)/node-chrome-debug:$(VERSION) .

generate_firefoxdebug:
	cd ./NodeDebug && ./generate.sh NodeFirefoxDebug node-firefox Firefox $(VERSION)

firefoxdebug: generate_firefoxdebug firefox
	cd ./NodeFirefoxDebug && docker build -t $(NAME)/node-firefox-debug:$(VERSION) .

tag_latest:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:latest
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:latest
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:latest
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:latest
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:latest

release: tag_latest
	@if ! docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/hub | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/hub version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/base
	docker push $(NAME)/hub
	docker push $(NAME)/node-base
	docker push $(NAME)/node-chrome
	docker push $(NAME)/node-firefox
	docker push $(NAME)/standalone-chrome
	docker push $(NAME)/standalone-firefox
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

test:
	./test.sh
	./sa-test.sh
	./test.sh debug

.PHONY: \
	all \
	base \
	build \
	chrome \
	chromedebug \
	ci \
	firefox \
	firefoxdebug \
	generate_chromedebug \
	generate_firefoxdebug \
	generate_standalone_chrome \
	generate_standalone_firefox \
	hub \
	nodebase \
	release \
	standalone_chrome \
	standalone_firefox \
	tag_latest \
	test
