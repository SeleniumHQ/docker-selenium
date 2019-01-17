NAME := $(or $(NAME),$(NAME),urosporo)
VERSION := $(or $(VERSION),$(VERSION),5.1.2)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),$(AUTHORS),Urosporo)
PLATFORM := $(shell uname -s)
BUILD_ARGS := $(BUILD_ARGS)
MAJOR := $(word 1,$(subst ., ,$(VERSION)))
MINOR := $(word 2,$(subst ., ,$(VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(VERSION)))

all: hub chrome firefox chrome_debug firefox_debug standalone_chrome standalone_firefox standalone_chrome_debug standalone_firefox_debug

generate_all:	\
	generate_hub \
	generate_nodebase \
	generate_chrome \
	generate_firefox \
	generate_chrome_debug \
	generate_firefox_debug \
	generate_standalone_firefox \
	generate_standalone_chrome \
	generate_standalone_firefox_debug \
	generate_standalone_chrome_debug

build: all

ci: build

base:
	cd ./Base && docker build $(BUILD_ARGS) -t $(NAME)/testbench-base:$(VERSION) .

generate_hub:
	cd ./Hub && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

hub: base generate_hub
	cd ./Hub && docker build $(BUILD_ARGS) -t $(NAME)/testbench-hub:$(VERSION) .

generate_nodebase:
	cd ./NodeBase && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

nodebase: base generate_nodebase
	cd ./NodeBase && docker build $(BUILD_ARGS) -t $(NAME)/testbench-node-base:$(VERSION) .

generate_chrome:
	cd ./NodeChrome && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome: nodebase generate_chrome
	cd ./NodeChrome && docker build $(BUILD_ARGS) -t $(NAME)/testbench-node-chrome:$(VERSION) .

generate_firefox:
	cd ./NodeFirefox && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

firefox: nodebase generate_firefox
	cd ./NodeFirefox && docker build $(BUILD_ARGS) -t $(NAME)/testbench-node-firefox:$(VERSION) .

generate_standalone_firefox:
	cd ./Standalone && ./generate.sh StandaloneFirefox testbench-node-firefox Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox: firefox generate_standalone_firefox
	cd ./StandaloneFirefox && docker build $(BUILD_ARGS) -t $(NAME)/testbench-standalone-firefox:$(VERSION) .

generate_standalone_firefox_debug:
	cd ./StandaloneDebug && ./generate.sh StandaloneFirefoxDebug testbench-node-firefox-debug Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox_debug: firefox_debug generate_standalone_firefox_debug
	cd ./StandaloneFirefoxDebug && docker build $(BUILD_ARGS) -t $(NAME)/testbench-standalone-firefox-debug:$(VERSION) .

generate_standalone_chrome:
	cd ./Standalone && ./generate.sh StandaloneChrome testbench-node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome: chrome generate_standalone_chrome
	cd ./StandaloneChrome && docker build $(BUILD_ARGS) -t $(NAME)/testbench-standalone-chrome:$(VERSION) .

generate_standalone_chrome_debug:
	cd ./StandaloneDebug && ./generate.sh StandaloneChromeDebug testbench-node-chrome-debug Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome_debug: chrome_debug generate_standalone_chrome_debug
	cd ./StandaloneChromeDebug && docker build $(BUILD_ARGS) -t $(NAME)/testbench-standalone-chrome-debug:$(VERSION) .

generate_chrome_debug:
	cd ./NodeDebug && ./generate.sh NodeChromeDebug testbench-node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome_debug: generate_chrome_debug chrome
	cd ./NodeChromeDebug && docker build $(BUILD_ARGS) -t $(NAME)/testbench-node-chrome-debug:$(VERSION) .

generate_firefox_debug:
	cd ./NodeDebug && ./generate.sh NodeFirefoxDebug testbench-node-firefox Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

firefox_debug: generate_firefox_debug firefox
	cd ./NodeFirefoxDebug && docker build $(BUILD_ARGS) -t $(NAME)/testbench-node-firefox-debug:$(VERSION) .

tag_latest:
	docker tag $(NAME)/testbench-base:$(VERSION) $(NAME)/testbench-base:latest
	docker tag $(NAME)/testbench-hub:$(VERSION) $(NAME)/testbench-hub:latest
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/testbench-node-base:latest
	docker tag $(NAME)/testbench-node-chrome:$(VERSION) $(NAME)/testbench-node-chrome:latest
	docker tag $(NAME)/testbench-node-firefox:$(VERSION) $(NAME)/testbench-node-firefox:latest
	docker tag $(NAME)/testbench-node-chrome-debug:$(VERSION) $(NAME)/testbench-node-chrome-debug:latest
	docker tag $(NAME)/testbench-node-firefox-debug:$(VERSION) $(NAME)/testbench-node-firefox-debug:latest
	docker tag $(NAME)/testbench-standalone-chrome:$(VERSION) $(NAME)/testbench-standalone-chrome:latest
	docker tag $(NAME)/testbench-standalone-firefox:$(VERSION) $(NAME)/testbench-standalone-firefox:latest
	docker tag $(NAME)/testbench-standalone-chrome-debug:$(VERSION) $(NAME)/testbench-standalone-chrome-debug:latest
	docker tag $(NAME)/testbench-standalone-firefox-debug:$(VERSION) $(NAME)/testbench-standalone-firefox-debug:latest

release_latest:
	docker push $(NAME)/testbench-base:latest
	docker push $(NAME)/testbench-hub:latest
	docker push $(NAME)/testbench-node-base:latest
	docker push $(NAME)/testbench-node-chrome:latest
	docker push $(NAME)/testbench-node-firefox:latest
	docker push $(NAME)/testbench-node-chrome-debug:latest
	docker push $(NAME)/testbench-node-firefox-debug:latest
	docker push $(NAME)/testbench-standalone-chrome:latest
	docker push $(NAME)/testbench-standalone-firefox:latest
	docker push $(NAME)/testbench-standalone-chrome-debug:latest
	docker push $(NAME)/testbench-standalone-firefox-debug:latest

tag_major_minor:
	docker tag $(NAME)/testbench-base:$(VERSION) $(NAME)/testbench-base:$(MAJOR)
	docker tag $(NAME)/testbench-hub:$(VERSION) $(NAME)/testbench-hub:$(MAJOR)
	docker tag $(NAME)/testbench-node-base:$(VERSION) $(NAME)/testbench-node-base:$(MAJOR)
	docker tag $(NAME)/testbench-node-chrome:$(VERSION) $(NAME)/testbench-node-chrome:$(MAJOR)
	docker tag $(NAME)/testbench-node-firefox:$(VERSION) $(NAME)/testbench-node-firefox:$(MAJOR)
	docker tag $(NAME)/testbench-node-chrome-debug:$(VERSION) $(NAME)/testbench-node-chrome-debug:$(MAJOR)
	docker tag $(NAME)/testbench-node-firefox-debug:$(VERSION) $(NAME)/testbench-node-firefox-debug:$(MAJOR)
	docker tag $(NAME)/testbench-standalone-chrome:$(VERSION) $(NAME)/testbench-standalone-chrome:$(MAJOR)
	docker tag $(NAME)/testbench-standalone-firefox:$(VERSION) $(NAME)/testbench-standalone-firefox:$(MAJOR)
	docker tag $(NAME)/testbench-standalone-chrome-debug:$(VERSION) $(NAME)/testbench-standalone-chrome-debug:$(MAJOR)
	docker tag $(NAME)/testbench-standalone-firefox-debug:$(VERSION) $(NAME)/testbench-standalone-firefox-debug:$(MAJOR)
	docker tag $(NAME)/testbench-base:$(VERSION) $(NAME)/testbench-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-hub:$(VERSION) $(NAME)/testbench-hub:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-node-base:$(VERSION) $(NAME)/testbench-node-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-node-chrome:$(VERSION) $(NAME)/testbench-node-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-node-firefox:$(VERSION) $(NAME)/testbench-node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-node-chrome-debug:$(VERSION) $(NAME)/testbench-node-chrome-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-node-firefox-debug:$(VERSION) $(NAME)/testbench-node-firefox-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-standalone-chrome:$(VERSION) $(NAME)/testbench-standalone-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-standalone-firefox:$(VERSION) $(NAME)/testbench-standalone-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-standalone-chrome-debug:$(VERSION) $(NAME)/testbench-standalone-chrome-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-standalone-firefox-debug:$(VERSION) $(NAME)/testbench-standalone-firefox-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/testbench-base:$(VERSION) $(NAME)/testbench-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-hub:$(VERSION) $(NAME)/testbench-hub:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-node-base:$(VERSION) $(NAME)/testbench-node-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-node-chrome:$(VERSION) $(NAME)/testbench-node-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-node-firefox:$(VERSION) $(NAME)/testbench-node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-node-chrome-debug:$(VERSION) $(NAME)/testbench-node-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-node-firefox-debug:$(VERSION) $(NAME)/testbench-node-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-standalone-chrome:$(VERSION) $(NAME)/testbench-standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-standalone-firefox:$(VERSION) $(NAME)/testbench-standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-standalone-chrome-debug:$(VERSION) $(NAME)/testbench-standalone-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/testbench-standalone-firefox-debug:$(VERSION) $(NAME)/testbench-standalone-firefox-debug:$(MAJOR_MINOR_PATCH)

release: tag_major_minor
	@if ! docker images $(NAME)/testbench-base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-hub | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-hub version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-node-base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-node-base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-node-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-node-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-node-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-node-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-node-chrome-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-node-chrome-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-node-firefox-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-node-firefox-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-standalone-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-standalone-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-standalone-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-standalone-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-standalone-chrome-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-standalone-chrome-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/testbench-standalone-firefox-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/testbench-standalone-firefox-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/testbench-base:$(VERSION)
	docker push $(NAME)/testbench-hub:$(VERSION)
	docker push $(NAME)/testbench-node-base:$(VERSION)
	docker push $(NAME)/testbench-node-chrome:$(VERSION)
	docker push $(NAME)/testbench-node-firefox:$(VERSION)
	docker push $(NAME)/testbench-node-chrome-debug:$(VERSION)
	docker push $(NAME)/testbench-node-firefox-debug:$(VERSION)
	docker push $(NAME)/testbench-standalone-chrome:$(VERSION)
	docker push $(NAME)/testbench-standalone-firefox:$(VERSION)
	docker push $(NAME)/testbench-standalone-chrome-debug:$(VERSION)
	docker push $(NAME)/testbench-standalone-firefox-debug:$(VERSION)
	docker push $(NAME)/testbench-base:$(MAJOR)
	docker push $(NAME)/testbench-hub:$(MAJOR)
	docker push $(NAME)/testbench-node-base:$(MAJOR)
	docker push $(NAME)/testbench-node-chrome:$(MAJOR)
	docker push $(NAME)/testbench-node-firefox:$(MAJOR)
	docker push $(NAME)/testbench-node-chrome-debug:$(MAJOR)
	docker push $(NAME)/testbench-node-firefox-debug:$(MAJOR)
	docker push $(NAME)/testbench-standalone-chrome:$(MAJOR)
	docker push $(NAME)/testbench-standalone-firefox:$(MAJOR)
	docker push $(NAME)/testbench-standalone-chrome-debug:$(MAJOR)
	docker push $(NAME)/testbench-standalone-firefox-debug:$(MAJOR)
	docker push $(NAME)/testbench-base:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-hub:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-node-base:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-node-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-node-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-node-chrome-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-node-firefox-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-standalone-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-standalone-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-standalone-chrome-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-standalone-firefox-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/testbench-base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-hub:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-node-base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-node-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-node-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-node-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-node-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-standalone-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/testbench-standalone-firefox-debug:$(MAJOR_MINOR_PATCH)

.PHONY: \
	all \
	base \
	build \
	chrome \
	chrome_debug \
	ci \
	firefox \
	firefox_debug \
	generate_all \
	generate_hub \
	generate_nodebase \
	generate_chrome \
	generate_firefox \
	generate_chrome_debug \
	generate_firefox_debug \
	generate_standalone_chrome \
	generate_standalone_firefox \
	generate_standalone_chrome_debug \
	generate_standalone_firefox_debug \
	hub \
	nodebase \
	release \
	standalone_chrome \
	standalone_firefox \
	standalone_chrome_debug \
	standalone_firefox_debug \
	tag_latest