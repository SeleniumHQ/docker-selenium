NAME := $(or $(NAME),$(NAME),selenium)
VERSION := $(or $(VERSION),$(VERSION),4.0.0-alpha-5-2020515)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),$(AUTHORS),SeleniumHQ)
PLATFORM := $(shell uname -s)
BUILD_ARGS := $(BUILD_ARGS)
MAJOR := $(word 1,$(subst ., ,$(VERSION)))
MINOR := $(word 2,$(subst ., ,$(VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(VERSION)))

all: hub distributor router sessions chrome firefox opera standalone_chrome standalone_firefox standalone_opera

generate_all:	\
	generate_hub \
	generate_distributor \
	generate_router \
	generate_sessions \
	generate_node_base \
	generate_chrome \
	generate_firefox \
	generate_opera \
	generate_standalone_firefox \
	generate_standalone_chrome \
	generate_standalone_opera

build: all

ci: build test

base:
	cd ./Base && docker build $(BUILD_ARGS) -t $(NAME)/base:$(VERSION) .

generate_hub:
	cd ./Hub && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

hub: base generate_hub
	cd ./Hub && docker build $(BUILD_ARGS) -t $(NAME)/hub:$(VERSION) .

generate_distributor:
	cd ./Distributor && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

distributor: base generate_distributor
	cd ./Distributor && docker build $(BUILD_ARGS) -t $(NAME)/distributor:$(VERSION) .

generate_router:
	cd ./Router && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

router: base generate_router
	cd ./Router && docker build $(BUILD_ARGS) -t $(NAME)/router:$(VERSION) .

generate_sessions:
	cd ./Sessions && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

sessions: base generate_sessions
	cd ./Sessions && docker build $(BUILD_ARGS) -t $(NAME)/sessions:$(VERSION) .

generate_node_base:
	cd ./NodeBase && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

node_base: base generate_node_base
	cd ./NodeBase && docker build $(BUILD_ARGS) -t $(NAME)/node-base:$(VERSION) .

generate_chrome:
	cd ./NodeChrome && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome: node_base generate_chrome
	cd ./NodeChrome && docker build $(BUILD_ARGS) -t $(NAME)/node-chrome:$(VERSION) .

generate_firefox:
	cd ./NodeFirefox && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

firefox: node_base generate_firefox
	cd ./NodeFirefox && docker build $(BUILD_ARGS) -t $(NAME)/node-firefox:$(VERSION) .

generate_opera:
	cd ./NodeOpera && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

opera: node_base generate_opera
	cd ./NodeOpera && docker build $(BUILD_ARGS) -t $(NAME)/node-opera:$(VERSION) .

generate_standalone_firefox:
	cd ./Standalone && ./generate.sh StandaloneFirefox node-firefox Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox: firefox generate_standalone_firefox
	cd ./StandaloneFirefox && docker build $(BUILD_ARGS) -t $(NAME)/standalone-firefox:$(VERSION) .

generate_standalone_chrome:
	cd ./Standalone && ./generate.sh StandaloneChrome node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome: chrome generate_standalone_chrome
	cd ./StandaloneChrome && docker build $(BUILD_ARGS) -t $(NAME)/standalone-chrome:$(VERSION) .

generate_standalone_opera:
	cd ./Standalone && ./generate.sh StandaloneOpera node-opera Opera $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_opera: opera generate_standalone_opera
	cd ./StandaloneOpera && docker build $(BUILD_ARGS) -t $(NAME)/standalone-opera:$(VERSION) .

tag_latest:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:latest
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:latest
	docker tag $(NAME)/distributor:$(VERSION) $(NAME)/distributor:latest
	docker tag $(NAME)/router:$(VERSION) $(NAME)/router:latest
	docker tag $(NAME)/sessions:$(VERSION) $(NAME)/sessions:latest
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:latest
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:latest
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:latest
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:latest
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:latest

release_latest:
	docker push $(NAME)/base:latest
	docker push $(NAME)/hub:latest
	docker push $(NAME)/distributor:latest
	docker push $(NAME)/router:latest
	docker push $(NAME)/sessions:latest
	docker push $(NAME)/node-base:latest
	docker push $(NAME)/node-chrome:latest
	docker push $(NAME)/node-firefox:latest
	docker push $(NAME)/node-opera:latest
	docker push $(NAME)/standalone-chrome:latest
	docker push $(NAME)/standalone-firefox:latest
	docker push $(NAME)/standalone-opera:latest

tag_major_minor:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR)
	docker tag $(NAME)/distributor:$(VERSION) $(NAME)/distributor:$(MAJOR)
	docker tag $(NAME)/router:$(VERSION) $(NAME)/router:$(MAJOR)
	docker tag $(NAME)/sessions:$(VERSION) $(NAME)/sessions:$(MAJOR)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR)
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:$(MAJOR)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR)
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:$(MAJOR)
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR).$(MINOR)
	docker tag $(NAME)/distributor:$(VERSION) $(NAME)/distributor:$(MAJOR).$(MINOR)
	docker tag $(NAME)/router:$(VERSION) $(NAME)/router:$(MAJOR).$(MINOR)
	docker tag $(NAME)/sessions:$(VERSION) $(NAME)/sessions:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:$(MAJOR).$(MINOR)
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/distributor:$(VERSION) $(NAME)/distributor:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/router:$(VERSION) $(NAME)/router:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/sessions:$(VERSION) $(NAME)/sessions:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-opera:$(VERSION) $(NAME)/node-opera:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-opera:$(VERSION) $(NAME)/standalone-opera:$(MAJOR_MINOR_PATCH)

release: tag_major_minor
	@if ! docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/hub | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/hub version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/distributor | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/distributor version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/router | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/router version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/sessions | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/sessions version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-opera | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-opera version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-opera | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-opera version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/base:$(VERSION)
	docker push $(NAME)/hub:$(VERSION)
	docker push $(NAME)/distributor:$(VERSION)
	docker push $(NAME)/router:$(VERSION)
	docker push $(NAME)/sessions:$(VERSION)
	docker push $(NAME)/node-base:$(VERSION)
	docker push $(NAME)/node-chrome:$(VERSION)
	docker push $(NAME)/node-firefox:$(VERSION)
	docker push $(NAME)/node-opera:$(VERSION)
	docker push $(NAME)/standalone-chrome:$(VERSION)
	docker push $(NAME)/standalone-firefox:$(VERSION)
	docker push $(NAME)/standalone-opera:$(VERSION)
	docker push $(NAME)/base:$(MAJOR)
	docker push $(NAME)/hub:$(MAJOR)
	docker push $(NAME)/distributor:$(MAJOR)
	docker push $(NAME)/router:$(MAJOR)
	docker push $(NAME)/sessions:$(MAJOR)
	docker push $(NAME)/node-base:$(MAJOR)
	docker push $(NAME)/node-chrome:$(MAJOR)
	docker push $(NAME)/node-firefox:$(MAJOR)
	docker push $(NAME)/node-opera:$(MAJOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR)
	docker push $(NAME)/standalone-opera:$(MAJOR)
	docker push $(NAME)/base:$(MAJOR).$(MINOR)
	docker push $(NAME)/hub:$(MAJOR).$(MINOR)
	docker push $(NAME)/distributor:$(MAJOR).$(MINOR)
	docker push $(NAME)/router:$(MAJOR).$(MINOR)
	docker push $(NAME)/sessions:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-opera:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-opera:$(MAJOR).$(MINOR)
	docker push $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/distributor:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/router:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/sessions:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-opera:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-opera:$(MAJOR_MINOR_PATCH)

test: test_chrome \
 test_firefox \
 test_opera \
 test_chrome_standalone \
 test_firefox_standalone \
 test_opera_standalone


test_chrome:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChrome

test_chrome_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChrome

test_firefox:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefox

test_firefox_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefox

test_opera:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeOpera

test_opera_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneOpera

.PHONY: \
	all \
	base \
	build \
	chrome \
	ci \
	firefox \
	opera \
	generate_all \
	generate_hub \
	generate_distributor \
	generate_router \
	generate_sessions \
	generate_node_base \
	generate_chrome \
	generate_firefox \
	generate_opera \
	generate_standalone_chrome \
	generate_standalone_firefox \
	generate_standalone_opera \
	hub \
	distributor \
	router \
	sessions \
	node_base \
	release \
	standalone_chrome \
	standalone_firefox \
	tag_latest \
	test
