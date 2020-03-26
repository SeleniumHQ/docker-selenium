NAME := $(or $(NAME),$(NAME),selenium)
VERSION := $(or $(VERSION),$(VERSION),3.141.59-20200326)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),$(AUTHORS),SeleniumHQ)
PLATFORM := $(shell uname -s)
BUILD_ARGS := $(BUILD_ARGS)
MAJOR := $(word 1,$(subst ., ,$(VERSION)))
MINOR := $(word 2,$(subst ., ,$(VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(VERSION)))

all: hub chrome firefox opera chrome_debug firefox_debug opera_debug standalone_chrome standalone_firefox standalone_opera standalone_chrome_debug standalone_firefox_debug standalone_opera_debug

generate_all:	\
	generate_hub \
	generate_nodebase \
	generate_chrome \
	generate_firefox \
	generate_opera \
	generate_chrome_debug \
	generate_firefox_debug \
	generate_opera_debug \
	generate_standalone_firefox \
	generate_standalone_chrome \
	generate_standalone_opera \
	generate_standalone_firefox_debug \
	generate_standalone_chrome_debug \
	generate_standalone_opera_debug

build: all

ci: build test

base:
	cd ./Base && docker build $(BUILD_ARGS) -t $(NAME)/base:$(VERSION) .

generate_hub:
	cd ./Hub && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

hub: base generate_hub
	cd ./Hub && docker build $(BUILD_ARGS) -t $(NAME)/hub:$(VERSION) .

generate_nodebase:
	cd ./NodeBase && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

nodebase: base generate_nodebase
	cd ./NodeBase && docker build $(BUILD_ARGS) -t $(NAME)/node-base:$(VERSION) .

generate_chrome:
	cd ./NodeChrome && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome: nodebase generate_chrome
	cd ./NodeChrome && docker build $(BUILD_ARGS) -t $(NAME)/node-chrome:$(VERSION) .

generate_firefox:
	cd ./NodeFirefox && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

firefox: nodebase generate_firefox
	cd ./NodeFirefox && docker build $(BUILD_ARGS) -t $(NAME)/node-firefox:$(VERSION) .

generate_opera:
	cd ./NodeOpera && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

opera: nodebase generate_opera
	cd ./NodeOpera && docker build $(BUILD_ARGS) -t $(NAME)/node-opera:$(VERSION) .

generate_standalone_firefox:
	cd ./Standalone && ./generate.sh StandaloneFirefox node-firefox Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox: firefox generate_standalone_firefox
	cd ./StandaloneFirefox && docker build $(BUILD_ARGS) -t $(NAME)/standalone-firefox:$(VERSION) .

generate_standalone_firefox_debug:
	cd ./StandaloneDebug && ./generate.sh StandaloneFirefoxDebug node-firefox-debug Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox_debug: firefox_debug generate_standalone_firefox_debug
	cd ./StandaloneFirefoxDebug && docker build $(BUILD_ARGS) -t $(NAME)/standalone-firefox-debug:$(VERSION) .

generate_standalone_chrome:
	cd ./Standalone && ./generate.sh StandaloneChrome node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome: chrome generate_standalone_chrome
	cd ./StandaloneChrome && docker build $(BUILD_ARGS) -t $(NAME)/standalone-chrome:$(VERSION) .

generate_standalone_chrome_debug:
	cd ./StandaloneDebug && ./generate.sh StandaloneChromeDebug node-chrome-debug Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome_debug: chrome_debug generate_standalone_chrome_debug
	cd ./StandaloneChromeDebug && docker build $(BUILD_ARGS) -t $(NAME)/standalone-chrome-debug:$(VERSION) .

generate_standalone_opera:
	cd ./Standalone && ./generate.sh StandaloneOpera node-opera Opera $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_opera: opera generate_standalone_opera
	cd ./StandaloneOpera && docker build $(BUILD_ARGS) -t $(NAME)/standalone-opera:$(VERSION) .

generate_standalone_opera_debug:
	cd ./StandaloneDebug && ./generate.sh StandaloneOperaDebug node-opera-debug Opera $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_opera_debug: opera_debug generate_standalone_opera_debug
	cd ./StandaloneOperaDebug && docker build $(BUILD_ARGS) -t $(NAME)/standalone-opera-debug:$(VERSION) .

generate_chrome_debug:
	cd ./NodeDebug && ./generate.sh NodeChromeDebug node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome_debug: generate_chrome_debug chrome
	cd ./NodeChromeDebug && docker build $(BUILD_ARGS) -t $(NAME)/node-chrome-debug:$(VERSION) .

generate_firefox_debug:
	cd ./NodeDebug && ./generate.sh NodeFirefoxDebug node-firefox Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

firefox_debug: generate_firefox_debug firefox
	cd ./NodeFirefoxDebug && docker build $(BUILD_ARGS) -t $(NAME)/node-firefox-debug:$(VERSION) .

generate_opera_debug:
	cd ./NodeDebug && ./generate.sh NodeOperaDebug node-opera Opera $(VERSION) $(NAMESPACE) $(AUTHORS)

opera_debug: generate_opera_debug opera
	cd ./NodeOperaDebug && docker build $(BUILD_ARGS) -t $(NAME)/node-opera-debug:$(VERSION) .

tag_latest:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:latest
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:latest
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:latest
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:latest
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:latest
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:latest
	docker tag $(NAME)/node-opera-debug:$(VERSION) $(NAME)/node-opera-debug:latest
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:latest
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:latest
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:latest
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:latest
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:latest
	docker tag $(NAME)/standalone-opera-debug:$(VERSION) $(NAME)/standalone-opera-debug:latest

release_latest:
	docker push $(NAME)/base:latest
	docker push $(NAME)/hub:latest
	docker push $(NAME)/node-base:latest
	docker push $(NAME)/node-chrome:latest
	docker push $(NAME)/node-firefox:latest
	docker push $(NAME)/node-opera:latest
	docker push $(NAME)/node-chrome-debug:latest
	docker push $(NAME)/node-firefox-debug:latest
	docker push $(NAME)/node-opera-debug:latest
	docker push $(NAME)/standalone-chrome:latest
	docker push $(NAME)/standalone-firefox:latest
	docker push $(NAME)/standalone-opera:latest
	docker push $(NAME)/standalone-chrome-debug:latest
	docker push $(NAME)/standalone-firefox-debug:latest
	docker push $(NAME)/standalone-opera-debug:latest

tag_major_minor:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR)
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:$(MAJOR)
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:$(MAJOR)
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:$(MAJOR)
	docker tag $(NAME)/node-opera-debug:$(VERSION) $(NAME)/node-opera-debug:$(MAJOR)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR)
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:$(MAJOR)
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:$(MAJOR)
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:$(MAJOR)
	docker tag $(NAME)/standalone-opera-debug:$(VERSION) $(NAME)/standalone-opera-debug:$(MAJOR)
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-opera-debug:$(VERSION) $(NAME)/node-opera-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-opera-debug:$(VERSION) $(NAME)/standalone-opera-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-opera-debug:$(VERSION) $(NAME)/node-opera-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-opera-debug:$(VERSION) $(NAME)/standalone-opera-debug:$(MAJOR_MINOR_PATCH)

release: tag_major_minor
	@if ! docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/hub | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/hub version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-opera | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-opera version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-chrome-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-firefox-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-opera-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-opera-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-opera | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-opera version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-chrome-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-firefox-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-opera-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-opera-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/base:$(VERSION)
	docker push $(NAME)/hub:$(VERSION)
	docker push $(NAME)/node-base:$(VERSION)
	docker push $(NAME)/node-chrome:$(VERSION)
	docker push $(NAME)/node-firefox:$(VERSION)
	docker push $(NAME)/node-opera:$(VERSION)
	docker push $(NAME)/node-chrome-debug:$(VERSION)
	docker push $(NAME)/node-firefox-debug:$(VERSION)
	docker push $(NAME)/node-opera-debug:$(VERSION)
	docker push $(NAME)/standalone-chrome:$(VERSION)
	docker push $(NAME)/standalone-firefox:$(VERSION)
	docker push $(NAME)/standalone-opera:$(VERSION)
	docker push $(NAME)/standalone-chrome-debug:$(VERSION)
	docker push $(NAME)/standalone-firefox-debug:$(VERSION)
	docker push $(NAME)/standalone-opera-debug:$(VERSION)
	docker push $(NAME)/base:$(MAJOR)
	docker push $(NAME)/hub:$(MAJOR)
	docker push $(NAME)/node-base:$(MAJOR)
	docker push $(NAME)/node-chrome:$(MAJOR)
	docker push $(NAME)/node-firefox:$(MAJOR)
	docker push $(NAME)/node-opera:$(MAJOR)
	docker push $(NAME)/node-chrome-debug:$(MAJOR)
	docker push $(NAME)/node-firefox-debug:$(MAJOR)
	docker push $(NAME)/node-opera-debug:$(MAJOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR)
	docker push $(NAME)/standalone-opera:$(MAJOR)
	docker push $(NAME)/standalone-chrome-debug:$(MAJOR)
	docker push $(NAME)/standalone-firefox-debug:$(MAJOR)
	docker push $(NAME)/standalone-opera-debug:$(MAJOR)
	docker push $(NAME)/base:$(MAJOR).$(MINOR)
	docker push $(NAME)/hub:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-opera:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-chrome-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-firefox-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-opera-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-opera:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chrome-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-firefox-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-opera-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-opera:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-opera-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-opera:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-opera-debug:$(MAJOR_MINOR_PATCH)

test: test_chrome \
 test_firefox \
 test_opera \
 test_chrome_debug \
 test_firefox_debug \
 test_opera_debug \
 test_chrome_standalone \
 test_firefox_standalone \
 test_opera_standalone \
 test_chrome_standalone_debug \
 test_firefox_standalone_debug \
 test_opera_standalone_debug


test_chrome:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChrome

test_chrome_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChromeDebug

test_chrome_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChrome

test_chrome_standalone_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChromeDebug

test_firefox:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefox

test_firefox_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefoxDebug

test_firefox_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefox

test_firefox_standalone_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefoxDebug

test_opera:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeOpera

test_opera_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeOperaDebug

test_opera_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneOpera

test_opera_standalone_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneOperaDebug


.PHONY: \
	all \
	base \
	build \
	chrome \
	chrome_debug \
	ci \
	firefox \
	firefox_debug \
	opera \
	opera_debug \
	generate_all \
	generate_hub \
	generate_nodebase \
	generate_chrome \
	generate_firefox \
	generate_opera \
	generate_chrome_debug \
	generate_firefox_debug \
	generate_opera_debug \
	generate_standalone_chrome \
	generate_standalone_firefox \
	generate_standalone_opera \
	generate_standalone_chrome_debug \
	generate_standalone_firefox_debug \
	generate_standalone_opera_debug \
	hub \
	nodebase \
	release \
	standalone_chrome \
	standalone_firefox \
	standalone_chrome_debug \
	standalone_firefox_debug \
	tag_latest \
	test
