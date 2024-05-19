NAME := $(or $(NAME),$(NAME),selenium)
CURRENT_DATE := $(shell date '+%Y%m%d')
BUILD_DATE := $(or $(BUILD_DATE),$(BUILD_DATE),$(CURRENT_DATE))
BASE_RELEASE := $(or $(BASE_RELEASE),$(BASE_RELEASE),selenium-4.21.0)
BASE_VERSION := $(or $(BASE_VERSION),$(BASE_VERSION),4.21.0)
BINDING_VERSION := $(or $(BINDING_VERSION),$(BINDING_VERSION),4.21.0)
BASE_RELEASE_NIGHTLY := $(or $(BASE_RELEASE_NIGHTLY),$(BASE_RELEASE_NIGHTLY),nightly)
BASE_VERSION_NIGHTLY := $(or $(BASE_VERSION_NIGHTLY),$(BASE_VERSION_NIGHTLY),4.22.0-SNAPSHOT)
VERSION := $(or $(VERSION),$(VERSION),4.21.0)
TAG_VERSION := $(VERSION)-$(BUILD_DATE)
CHART_VERSION_NIGHTLY := $(or $(CHART_VERSION_NIGHTLY),$(CHART_VERSION_NIGHTLY),1.0.0-nightly)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),$(AUTHORS),SeleniumHQ)
PUSH_IMAGE := $(or $(PUSH_IMAGE),$(PUSH_IMAGE),false)
FROM_IMAGE_ARGS := --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(TAG_VERSION) --build-arg AUTHORS=$(AUTHORS)
BUILD_ARGS := $(BUILD_ARGS)
MAJOR := $(word 1,$(subst ., ,$(TAG_VERSION)))
MINOR := $(word 2,$(subst ., ,$(TAG_VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(TAG_VERSION)))
FFMPEG_TAG_VERSION := $(or $(FFMPEG_TAG_VERSION),$(FFMPEG_TAG_VERSION),ffmpeg-6.1.1)
FFMPEG_BASED_NAME := $(or $(FFMPEG_BASED_NAME),$(FFMPEG_BASED_NAME),linuxserver)
FFMPEG_BASED_TAG := $(or $(FFMPEG_BASED_TAG),$(FFMPEG_BASED_TAG),version-6.1.1-cli)
PLATFORMS := $(or $(PLATFORMS),$(PLATFORMS),linux/amd64)

all: hub \
	distributor \
	router \
	sessions \
	sessionqueue \
	event_bus \
	chrome \
	edge \
	firefox \
	docker \
	standalone_chrome \
	standalone_edge \
	standalone_firefox \
	standalone_docker \
	video

set_build_nightly:
	echo BASE_VERSION=$(BASE_VERSION_NIGHTLY) > .env ; \
	echo BASE_RELEASE=$(BASE_RELEASE_NIGHTLY) >> .env ;
	echo "Execute 'source .env' to set the environment variables"

docker_buildx_setup:
	sudo apt-get install --upgrade docker-buildx-plugin
	docker buildx version
	docker buildx use default

build_nightly:
	BASE_VERSION=$(BASE_VERSION_NIGHTLY) BASE_RELEASE=$(BASE_RELEASE_NIGHTLY) make build

build: all

ci: build test

base:
	cd ./Base && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --load --build-arg VERSION=$(BASE_VERSION) --build-arg RELEASE=$(BASE_RELEASE) --build-arg AUTHORS=$(AUTHORS) --load -t $(NAME)/base:$(TAG_VERSION) .

base_nightly:
	cd ./Base && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg VERSION=$(BASE_VERSION_NIGHTLY) --build-arg RELEASE=$(BASE_RELEASE_NIGHTLY) --build-arg AUTHORS=$(AUTHORS) --load -t $(NAME)/base:$(TAG_VERSION) .

hub: base
	cd ./Hub && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/hub:$(TAG_VERSION) .

distributor: base
	cd ./Distributor && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/distributor:$(TAG_VERSION) .

router: base
	cd ./Router && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/router:$(TAG_VERSION) .

sessions: base
	cd ./Sessions && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/sessions:$(TAG_VERSION) .

sessionqueue: base
	cd ./SessionQueue && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/session-queue:$(TAG_VERSION) .

event_bus: base
	cd ./EventBus && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/event-bus:$(TAG_VERSION) .

node_base: base
	cd ./NodeBase && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/node-base:$(TAG_VERSION) .

chrome: node_base
	cd ./NodeChrome && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/node-chrome:$(TAG_VERSION) .

chrome_dev:
	cd ./NodeChrome && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg CHROME_VERSION=google-chrome-unstable --load -t $(NAME)/node-chrome:dev .

chrome_beta:
	cd ./NodeChrome && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg CHROME_VERSION=google-chrome-beta --load -t $(NAME)/node-chrome:beta .

edge: node_base
	cd ./NodeEdge && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/node-edge:$(TAG_VERSION) .

edge_dev:
	cd ./NodeEdge && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg EDGE_VERSION=microsoft-edge-dev --load -t $(NAME)/node-edge:dev .

edge_beta:
	cd ./NodeEdge && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg EDGE_VERSION=microsoft-edge-beta --load -t $(NAME)/node-edge:beta .

firefox: node_base
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/node-firefox:$(TAG_VERSION) .

firefox_dev:
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load --build-arg FIREFOX_VERSION=nightly-latest -t $(NAME)/node-firefox:dev .

firefox_beta:
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load --build-arg FIREFOX_VERSION=beta-latest -t $(NAME)/node-firefox:beta .

docker: base
	cd ./NodeDocker && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/node-docker:$(TAG_VERSION) .

standalone_docker: docker
	cd ./StandaloneDocker && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --load -t $(NAME)/standalone-docker:$(TAG_VERSION) .

standalone_firefox: firefox
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-firefox --load -t $(NAME)/standalone-firefox:$(TAG_VERSION) .

standalone_firefox_dev: firefox_dev
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-firefox --load -t $(NAME)/standalone-firefox:dev .

standalone_firefox_beta: firefox_beta
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-firefox --load -t $(NAME)/standalone-firefox:beta .

standalone_chrome: chrome
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-chrome --load -t $(NAME)/standalone-chrome:$(TAG_VERSION) .

standalone_chrome_dev: chrome_dev
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-chrome --load -t $(NAME)/standalone-chrome:dev .

standalone_chrome_beta: chrome_beta
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:beta .

standalone_edge: edge
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-edge --load -t $(NAME)/standalone-edge:$(TAG_VERSION) .

standalone_edge_dev: edge_dev
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-edge --load -t $(NAME)/standalone-edge:dev .

standalone_edge_beta: edge_beta
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-edge --load -t $(NAME)/standalone-edge:beta .

video:
	cd ./Video && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(FFMPEG_BASED_NAME) --build-arg BASED_TAG=$(FFMPEG_BASED_TAG) --load -t $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) .

count_image_layers:
	docker history $(NAME)/base:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/hub:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/distributor:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/router:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/sessions:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/session-queue:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/event-bus:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-base:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-chrome:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-edge:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-firefox:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-docker:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-chrome:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-edge:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-firefox:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-docker:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) -q | wc -l

chrome_upgrade_version:
	cd ./NodeChrome && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(VERSION) --build-arg AUTHORS=$(AUTHORS) --load -t $(NAME)/node-chrome:$(TAG_VERSION) .
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-chrome --load -t $(NAME)/standalone-chrome:$(TAG_VERSION) .
	docker run --rm $(NAME)/standalone-chrome:$(TAG_VERSION) /opt/selenium/selenium-server.jar info --version
	docker run --rm $(NAME)/standalone-chrome:$(TAG_VERSION) google-chrome --version
	docker run --rm $(NAME)/standalone-chrome:$(TAG_VERSION) chromedriver --version

firefox_upgrade_version:
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(VERSION) --build-arg AUTHORS=$(AUTHORS) --load -t $(NAME)/node-firefox:$(TAG_VERSION) .
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-firefox --load -t $(NAME)/standalone-firefox:$(TAG_VERSION) .
	docker run --rm $(NAME)/standalone-firefox:$(TAG_VERSION) /opt/selenium/selenium-server.jar info --version
	docker run --rm $(NAME)/standalone-firefox:$(TAG_VERSION) firefox --version
	docker run --rm $(NAME)/standalone-firefox:$(TAG_VERSION) geckodriver --version

edge_upgrade_version:
	cd ./NodeEdge && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(VERSION) --build-arg AUTHORS=$(AUTHORS) --load -t $(NAME)/node-edge:$(TAG_VERSION) .
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-edge --load -t $(NAME)/standalone-edge:$(TAG_VERSION) .
	docker run --rm $(NAME)/standalone-edge:$(TAG_VERSION) /opt/selenium/selenium-server.jar info --version
	docker run --rm $(NAME)/standalone-edge:$(TAG_VERSION) microsoft-edge --version
	docker run --rm $(NAME)/standalone-edge:$(TAG_VERSION) msedgedriver --version

# https://github.com/SeleniumHQ/docker-selenium/issues/992
# Additional tags for browser images
tag_and_push_browser_images: tag_and_push_chrome_images tag_and_push_firefox_images tag_and_push_edge_images

tag_and_push_chrome_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) chrome

tag_and_push_edge_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) edge

tag_and_push_firefox_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) firefox

tag_latest:
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:latest
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:latest
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:latest
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:latest
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:latest
	docker tag $(NAME)/session-queue:$(TAG_VERSION) $(NAME)/session-queue:latest
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:latest
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:latest
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:latest
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:latest
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:latest
	docker tag $(NAME)/standalone-edge:$(TAG_VERSION) $(NAME)/standalone-edge:latest
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:latest
	docker tag $(NAME)/standalone-docker:$(TAG_VERSION) $(NAME)/standalone-docker:latest
	docker tag $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) $(NAME)/video:latest

release_latest:
	docker push $(NAME)/base:latest
	docker push $(NAME)/hub:latest
	docker push $(NAME)/distributor:latest
	docker push $(NAME)/router:latest
	docker push $(NAME)/sessions:latest
	docker push $(NAME)/session-queue:latest
	docker push $(NAME)/event-bus:latest
	docker push $(NAME)/node-base:latest
	docker push $(NAME)/node-chrome:latest
	docker push $(NAME)/node-edge:latest
	docker push $(NAME)/node-firefox:latest
	docker push $(NAME)/node-docker:latest
	docker push $(NAME)/standalone-chrome:latest
	docker push $(NAME)/standalone-edge:latest
	docker push $(NAME)/standalone-firefox:latest
	docker push $(NAME)/standalone-docker:latest
	docker push $(NAME)/video:latest

tag_nightly:
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:nightly
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:nightly
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:nightly
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:nightly
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:nightly
	docker tag $(NAME)/session-queue:$(TAG_VERSION) $(NAME)/session-queue:nightly
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:nightly
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:nightly
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:nightly
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:nightly
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:nightly
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:nightly
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:nightly
	docker tag $(NAME)/standalone-edge:$(TAG_VERSION) $(NAME)/standalone-edge:nightly
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:nightly
	docker tag $(NAME)/standalone-docker:$(TAG_VERSION) $(NAME)/standalone-docker:nightly
	docker tag $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) $(NAME)/video:nightly

release_nightly:
	docker push $(NAME)/base:nightly
	docker push $(NAME)/hub:nightly
	docker push $(NAME)/distributor:nightly
	docker push $(NAME)/router:nightly
	docker push $(NAME)/sessions:nightly
	docker push $(NAME)/session-queue:nightly
	docker push $(NAME)/event-bus:nightly
	docker push $(NAME)/node-base:nightly
	docker push $(NAME)/node-chrome:nightly
	docker push $(NAME)/node-edge:nightly
	docker push $(NAME)/node-firefox:nightly
	docker push $(NAME)/node-docker:nightly
	docker push $(NAME)/standalone-chrome:nightly
	docker push $(NAME)/standalone-edge:nightly
	docker push $(NAME)/standalone-firefox:nightly
	docker push $(NAME)/standalone-docker:nightly
	docker push $(NAME)/video:nightly

tag_major_minor:
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR)
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:$(MAJOR)
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:$(MAJOR)
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:$(MAJOR)
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:$(MAJOR)
	docker tag $(NAME)/session-queue:$(TAG_VERSION) $(NAME)/session-queue:$(MAJOR)
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:$(MAJOR)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR)
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:$(MAJOR)
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:$(MAJOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR)
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:$(MAJOR)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR)
	docker tag $(NAME)/standalone-edge:$(TAG_VERSION) $(NAME)/standalone-edge:$(MAJOR)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR)
	docker tag $(NAME)/standalone-docker:$(TAG_VERSION) $(NAME)/standalone-docker:$(MAJOR)
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:$(MAJOR).$(MINOR)
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:$(MAJOR).$(MINOR)
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:$(MAJOR).$(MINOR)
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:$(MAJOR).$(MINOR)
	docker tag $(NAME)/session-queue:$(TAG_VERSION) $(NAME)/session-queue:$(MAJOR).$(MINOR)
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-edge:$(TAG_VERSION) $(NAME)/standalone-edge:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-docker:$(TAG_VERSION) $(NAME)/standalone-docker:$(MAJOR).$(MINOR)
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/session-queue:$(TAG_VERSION) $(NAME)/session-queue:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-edge:$(TAG_VERSION) $(NAME)/standalone-edge:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-docker:$(TAG_VERSION) $(NAME)/standalone-docker:$(MAJOR_MINOR_PATCH)

release: tag_major_minor
	@if ! docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/base version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/hub | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/hub version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/distributor | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/distributor version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/router | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/router version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/sessions | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/sessions version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/session-queue | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/session-queue version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/event-bus | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/event-bus version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-base | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-base version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-chrome version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-edge | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-edge version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-firefox version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-docker | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-docker version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-chrome version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-edge | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-edge version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-firefox version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-docker | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-docker version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/base:$(TAG_VERSION)
	docker push $(NAME)/hub:$(TAG_VERSION)
	docker push $(NAME)/distributor:$(TAG_VERSION)
	docker push $(NAME)/router:$(TAG_VERSION)
	docker push $(NAME)/sessions:$(TAG_VERSION)
	docker push $(NAME)/session-queue:$(TAG_VERSION)
	docker push $(NAME)/event-bus:$(TAG_VERSION)
	docker push $(NAME)/node-base:$(TAG_VERSION)
	docker push $(NAME)/node-chrome:$(TAG_VERSION)
	docker push $(NAME)/node-edge:$(TAG_VERSION)
	docker push $(NAME)/node-firefox:$(TAG_VERSION)
	docker push $(NAME)/node-docker:$(TAG_VERSION)
	docker push $(NAME)/standalone-chrome:$(TAG_VERSION)
	docker push $(NAME)/standalone-edge:$(TAG_VERSION)
	docker push $(NAME)/standalone-firefox:$(TAG_VERSION)
	docker push $(NAME)/standalone-docker:$(TAG_VERSION)
	docker push $(NAME)/base:$(MAJOR)
	docker push $(NAME)/hub:$(MAJOR)
	docker push $(NAME)/distributor:$(MAJOR)
	docker push $(NAME)/router:$(MAJOR)
	docker push $(NAME)/sessions:$(MAJOR)
	docker push $(NAME)/session-queue:$(MAJOR)
	docker push $(NAME)/event-bus:$(MAJOR)
	docker push $(NAME)/node-base:$(MAJOR)
	docker push $(NAME)/node-chrome:$(MAJOR)
	docker push $(NAME)/node-edge:$(MAJOR)
	docker push $(NAME)/node-firefox:$(MAJOR)
	docker push $(NAME)/node-docker:$(MAJOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR)
	docker push $(NAME)/standalone-edge:$(MAJOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR)
	docker push $(NAME)/standalone-docker:$(MAJOR)
	docker push $(NAME)/base:$(MAJOR).$(MINOR)
	docker push $(NAME)/hub:$(MAJOR).$(MINOR)
	docker push $(NAME)/distributor:$(MAJOR).$(MINOR)
	docker push $(NAME)/router:$(MAJOR).$(MINOR)
	docker push $(NAME)/sessions:$(MAJOR).$(MINOR)
	docker push $(NAME)/session-queue:$(MAJOR).$(MINOR)
	docker push $(NAME)/event-bus:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-edge:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-docker:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-edge:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-docker:$(MAJOR).$(MINOR)
	docker push $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/distributor:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/router:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/sessions:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/session-queue:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/event-bus:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-edge:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-docker:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-edge:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-docker:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE)

test: test_chrome \
 test_firefox \
 test_chrome_standalone \
 test_firefox_standalone \
 test_edge \
 test_edge_standalone


test_chrome:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) ./tests/bootstrap.sh NodeChrome

test_chrome_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) ./tests/bootstrap.sh StandaloneChrome

test_edge:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) ./tests/bootstrap.sh NodeEdge

test_edge_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) ./tests/bootstrap.sh StandaloneEdge

test_firefox:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) ./tests/bootstrap.sh NodeFirefox

test_firefox_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) ./tests/bootstrap.sh StandaloneFirefox

test_parallel: hub chrome firefox edge
	sudo rm -rf ./tests/tests
	for node in DeploymentAutoscaling JobAutoscaling ; do \
			cd ./tests || true ; \
			echo TAG=$(TAG_VERSION) > .env ; \
			echo TEST_DRAIN_AFTER_SESSION_COUNT=$(or $(TEST_DRAIN_AFTER_SESSION_COUNT), 0) >> .env ; \
			echo TEST_PARALLEL_HARDENING=$(or $(TEST_PARALLEL_HARDENING), "false") >> .env ; \
			echo LOG_LEVEL=$(or $(LOG_LEVEL), "INFO") >> .env ; \
			echo REQUEST_TIMEOUT=$(or $(REQUEST_TIMEOUT), 300) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			docker compose -f docker-compose-v3-test-parallel.yml up --no-log-prefix --exit-code-from tests --build ; \
	done

test_video_dynamic_name:
	VIDEO_FILE_NAME=auto TEST_DELAY_AFTER_TEST=10 \
	make test_video

# This should run on its own CI job. There is no need to combine it with the other tests.
# Its main purpose is to check that a video file was generated.
test_video: video hub chrome firefox edge
	# Running a few tests with docker compose to generate the videos
	sudo rm -rf ./tests/tests
	sudo rm -rf ./tests/videos; mkdir -p ./tests/videos
	for node in NodeChrome NodeFirefox NodeEdge ; do \
			cd ./tests || true ; \
			echo VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) > .env ; \
			echo TAG=$(TAG_VERSION) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			echo TEST_DELAY_AFTER_TEST=$(or $(TEST_DELAY_AFTER_TEST), 0) >> .env ; \
			if [ $$node = "NodeChrome" ] ; then \
					echo BROWSER=chrome >> .env ; \
					echo VIDEO_FILE_NAME=$${VIDEO_FILE_NAME:-"chrome_video.mp4"} >> .env ; \
					echo VIDEO_FILE_NAME_SUFFIX=$${VIDEO_FILE_NAME_SUFFIX:-"true"} >> .env ; \
			fi ; \
			if [ $$node = "NodeEdge" ] ; then \
					echo BROWSER=edge >> .env ; \
					echo VIDEO_FILE_NAME=$${VIDEO_FILE_NAME:-"edge_video.mp4"} >> .env ; \
					echo VIDEO_FILE_NAME_SUFFIX=$${VIDEO_FILE_NAME_SUFFIX:-"false"} >> .env ; \
			fi ; \
			if [ $$node = "NodeFirefox" ] ; then \
					echo BROWSER=firefox >> .env ; \
					echo VIDEO_FILE_NAME=$${VIDEO_FILE_NAME:-"firefox_video.mp4"} >> .env ; \
					echo VIDEO_FILE_NAME_SUFFIX=$${VIDEO_FILE_NAME_SUFFIX:-"true"} >> .env ; \
			fi ; \
			docker compose -f docker-compose-v3-test-video.yml up --abort-on-container-exit --build ; \
	done
	make test_video_integrity

test_node_relay: hub node_base standalone_firefox
	sudo rm -rf ./tests/tests
	for node in Android NodeFirefox ; do \
			cd ./tests || true ; \
			echo TAG=$(TAG_VERSION) > .env ; \
			echo LOG_LEVEL=$(or $(LOG_LEVEL), "INFO") >> .env ; \
			echo REQUEST_TIMEOUT=$(or $(REQUEST_TIMEOUT), 300) >> .env ; \
			echo SESSION_TIMEOUT=$(or $(SESSION_TIMEOUT), 300) >> .env ; \
			echo ANDROID_BASED_NAME=$(or $(ANDROID_BASED_NAME),budtmo) >> .env ; \
			echo ANDROID_BASED_IMAGE=$(or $(ANDROID_BASED_IMAGE),docker-android) >> .env ; \
			echo ANDROID_BASED_TAG=$(or $(ANDROID_BASED_TAG),emulator_14.0) >> .env ; \
			echo ANDROID_PLATFORM_API=$(or $(ANDROID_PLATFORM_API),14) >> .env ; \
			echo TEST_DELAY_AFTER_TEST=$(or $(TEST_DELAY_AFTER_TEST), 15) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo TEST_NODE_RELAY=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			docker compose -f docker-compose-v3-test-node-relay.yml up --no-log-prefix --exit-code-from tests --build ; \
			if [ $$? -ne 0 ]; then exit 1; fi ; \
	done

test_node_docker: hub standalone_docker standalone_chrome standalone_firefox standalone_edge video
	sudo rm -rf ./tests/tests
	sudo rm -rf ./tests/videos; mkdir -p ./tests/videos/Downloads
	sudo chmod -R 777 ./tests/videos
	for node in NodeChrome NodeFirefox NodeEdge ; do \
			cd tests || true ; \
			DOWNLOADS_DIR="./videos/Downloads" ; \
			sudo rm -rf $$DOWNLOADS_DIR/* ; \
			echo NAMESPACE=$(NAME) > .env ; \
			echo TAG=$(TAG_VERSION) >> .env ; \
			echo VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) >> .env ; \
			echo TEST_DRAIN_AFTER_SESSION_COUNT=$(or $(TEST_DRAIN_AFTER_SESSION_COUNT), 0) >> .env ; \
			echo TEST_PARALLEL_HARDENING=$(or $(TEST_PARALLEL_HARDENING), "false") >> .env ; \
			echo LOG_LEVEL=$(or $(LOG_LEVEL), "INFO") >> .env ; \
			echo REQUEST_TIMEOUT=$(or $(REQUEST_TIMEOUT), 300) >> .env ; \
			echo SELENIUM_ENABLE_MANAGED_DOWNLOADS=$(or $(SELENIUM_ENABLE_MANAGED_DOWNLOADS), "false") >> .env ; \
			echo TEST_DELAY_AFTER_TEST=$(or $(TEST_DELAY_AFTER_TEST), 5) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			echo HOST_IP=$$(hostname -I | awk '{print $$1}') >> .env ; \
			export $$(cat .env | xargs) ; \
			envsubst < config.toml > ./videos/config.toml ; \
			docker compose -f docker-compose-v3-test-node-docker.yaml up --no-log-prefix --exit-code-from tests --build ; \
			if [ $$? -ne 0 ]; then exit 1; fi ; \
			if [ -d "$$DOWNLOADS_DIR" ] && [ $$(ls -1q $$DOWNLOADS_DIR | wc -l) -eq 0 ]; then \
					echo "Mounted downloads directory is empty. Downloaded files could not be retrieved!" ; \
					exit 1 ; \
			fi ; \
	done
	make test_video_integrity

test_custom_ca_cert:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/customCACert/bootstrap.sh

chart_setup_env:
	./tests/charts/make/chart_setup_env.sh

chart_cluster_setup:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BUILD_DATE=$(BUILD_DATE) ./tests/charts/make/chart_cluster_setup.sh

chart_cluster_cleanup:
	./tests/charts/make/chart_cluster_cleanup.sh

chart_build_nightly:
	VERSION=$(CHART_VERSION_NIGHTLY) ./tests/charts/make/chart_build.sh

chart_build:
	VERSION=$(TAG_VERSION) ./tests/charts/make/chart_build.sh

test_video_integrity:
	# Using ffmpeg to verify file integrity
	# https://superuser.com/questions/100288/how-can-i-check-the-integrity-of-a-video-file-avi-mpeg-mp4
	list_files=$$(find ./tests/videos -type f -name "*.mp4"); \
	echo "Number of video files: $$(echo $$list_files | wc -w)"; \
	number_corrupted_files=0; \
	if [ -z "$$list_files" ]; then \
		echo "No video files found"; \
		exit 1; \
	fi; \
	for file in $$list_files; do \
		echo "Checking video file: $$file"; \
	  docker run -u $$(id -u) -v $$(pwd):$$(pwd) -w $$(pwd) --entrypoint="" $(FFMPEG_BASED_NAME)/ffmpeg:$(FFMPEG_BASED_TAG) ffmpeg -v error -i "$$file" -f null - ; \
	  if [ $$? -ne 0 ]; then \
	    echo "Video file $$file is corrupted"; \
	    number_corrupted_files=$$((number_corrupted_files+1)); \
	  fi; \
	  echo "------"; \
	done; \
	if [ $$((number_corrupted_files)) -gt 0 ]; then \
		echo "Number of corrupted video files: $$number_corrupted_files"; \
		exit 1; \
	fi

chart_test_template:
	./tests/charts/bootstrap.sh

chart_test_autoscaling_disabled:
	SELENIUM_GRID_AUTOSCALING=false TEST_DELAY_AFTER_TEST=15 CHART_ENABLE_TRACING=true SELENIUM_GRID_HOST=$$(hostname -i) RELEASE_NAME=selenium \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	./tests/charts/make/chart_test.sh NoAutoscaling

chart_test_autoscaling_deployment_https:
	CHART_FULL_DISTRIBUTED_MODE=true CHART_ENABLE_INGRESS_HOSTNAME=true CHART_ENABLE_BASIC_AUTH=true SELENIUM_GRID_PROTOCOL=https SELENIUM_GRID_PORT=443 \
	SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=1 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	./tests/charts/make/chart_test.sh DeploymentAutoscaling

chart_test_autoscaling_deployment:
	CHART_ENABLE_TRACING=true SELENIUM_GRID_HOST=$$(hostname -i) RELEASE_NAME=selenium \
	SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=1 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	./tests/charts/make/chart_test.sh DeploymentAutoscaling

chart_test_autoscaling_job_https:
	SELENIUM_GRID_PROTOCOL=https CHART_ENABLE_BASIC_AUTH=true RELEASE_NAME=selenium SELENIUM_GRID_PORT=443 SUB_PATH=/ \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	./tests/charts/make/chart_test.sh JobAutoscaling

chart_test_autoscaling_job_hostname:
	CHART_ENABLE_TRACING=true CHART_ENABLE_INGRESS_HOSTNAME=true CHART_ENABLE_BASIC_AUTH=true \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	./tests/charts/make/chart_test.sh JobAutoscaling

chart_test_autoscaling_job:
	CHART_ENABLE_TRACING=true CHART_FULL_DISTRIBUTED_MODE=true CHART_ENABLE_INGRESS_HOSTNAME=true SELENIUM_GRID_HOST=selenium-grid.local RELEASE_NAME=selenium SUB_PATH=/ \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	./tests/charts/make/chart_test.sh JobAutoscaling

.PHONY: \
	all \
	base \
	build \
	ci \
	chrome \
	edge \
	firefox \
	docker \
	hub \
	distributor \
	router \
	sessions \
	sessionqueue \
	event_bus \
	node_base \
	release \
	standalone_chrome \
	standalone_edge \
	standalone_firefox \
	standalone_docker \
	tag_latest \
	tag_and_push_browser_images \
	test \
	video
