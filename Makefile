NAME := selenium
VERSION := $(or $(VERSION),$(VERSION),'2.44.0')
PLATFORM := $(shell uname -s)

all: hub chrome firefox

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

tag_latest:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:latest
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:latest
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:latest
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:latest

release: tag_latest
	@if ! docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/hub | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/hub version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/base
	docker push $(NAME)/hub
	docker push $(NAME)/node-base
	docker push $(NAME)/node-chrome
	docker push $(NAME)/node-firefox
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

test:
	./test.sh

.PHONY: all base hub nodebase chrome firefox full tag_latest release build test
