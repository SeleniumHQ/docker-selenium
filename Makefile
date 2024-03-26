NAME := $(or $(NAME),$(NAME),selenium)
CURRENT_DATE := $(shell date '+%Y%m%d')
BUILD_DATE := $(or $(BUILD_DATE),$(BUILD_DATE),$(CURRENT_DATE))
BASE_RELEASE := $(or $(BASE_RELEASE),$(BASE_RELEASE),selenium-4.18.0)
BASE_VERSION := $(or $(BASE_VERSION),$(BASE_VERSION),4.18.1)
BASE_RELEASE_NIGHTLY := $(or $(BASE_RELEASE_NIGHTLY),$(BASE_RELEASE_NIGHTLY),nightly)
BASE_VERSION_NIGHTLY := $(or $(BASE_VERSION_NIGHTLY),$(BASE_VERSION_NIGHTLY),4.19.0-SNAPSHOT)
VERSION := $(or $(VERSION),$(VERSION),4.18.1)
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
FFMPEG_TAG_VERSION := $(or $(FFMPEG_TAG_VERSION),$(FFMPEG_TAG_VERSION),ffmpeg-6.1)
FFMPEG_BASED_NAME := $(or $(FFMPEG_BASED_NAME),$(FFMPEG_BASED_NAME),ndviet)
FFMPEG_BASED_TAG := $(or $(FFMPEG_BASED_TAG),$(FFMPEG_BASED_TAG),6.1-ubuntu2204)
PLATFORMS := $(or $(PLATFORMS),$(PLATFORMS),linux/arm64)

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

build_nightly:
	BASE_VERSION=$(BASE_VERSION_NIGHTLY) BASE_RELEASE=$(BASE_RELEASE_NIGHTLY) make build

build: all

ci: build test

base:
	cd ./Base && docker build $(BUILD_ARGS) --build-arg VERSION=$(BASE_VERSION) --build-arg RELEASE=$(BASE_RELEASE) -t $(NAME)/base:$(TAG_VERSION) .

base_nightly:
	cd ./Base && docker build $(BUILD_ARGS) --build-arg VERSION=$(BASE_VERSION_NIGHTLY) --build-arg RELEASE=$(BASE_RELEASE_NIGHTLY) -t $(NAME)/base:$(TAG_VERSION) .

hub: base
	cd ./Hub && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/hub:$(TAG_VERSION) .

distributor: base
	cd ./Distributor && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/distributor:$(TAG_VERSION) .

router: base
	cd ./Router && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/router:$(TAG_VERSION) .

sessions: base
	cd ./Sessions && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/sessions:$(TAG_VERSION) .

sessionqueue: base
	cd ./SessionQueue && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/session-queue:$(TAG_VERSION) .

event_bus: base
	cd ./EventBus && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/event-bus:$(TAG_VERSION) .

node_base: base
	cd ./NodeBase && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-base:$(TAG_VERSION) .

chrome: node_base
	cd ./NodeChrome && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-chrome:$(TAG_VERSION) .

chrome_dev:
	cd ./NodeChrome && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg CHROME_VERSION=google-chrome-unstable -t $(NAME)/node-chrome:dev .

chrome_beta:
	cd ./NodeChrome && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg CHROME_VERSION=google-chrome-beta -t $(NAME)/node-chrome:beta .

edge: node_base
	cd ./NodeEdge && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-edge:$(TAG_VERSION) .

edge_dev:
	cd ./NodeEdge && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg EDGE_VERSION=microsoft-edge-dev -t $(NAME)/node-edge:dev .

edge_beta:
	cd ./NodeEdge && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg EDGE_VERSION=microsoft-edge-beta -t $(NAME)/node-edge:beta .

firefox: node_base
	cd ./NodeFirefox && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-firefox:$(TAG_VERSION) .

firefox_dev:
	cd ./NodeFirefox && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg FIREFOX_VERSION=nightly-latest -t $(NAME)/node-firefox:dev .

firefox_beta:
	cd ./NodeFirefox && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg FIREFOX_VERSION=beta-latest -t $(NAME)/node-firefox:beta .

docker: base
	cd ./NodeDocker && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-docker:$(TAG_VERSION) .

standalone_docker: docker
	cd ./StandaloneDocker && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/standalone-docker:$(TAG_VERSION) .

standalone_firefox: firefox
	cd ./Standalone && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:$(TAG_VERSION) .

standalone_firefox_dev: firefox_dev
	cd ./Standalone && docker build $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:dev .

standalone_firefox_beta: firefox_beta
	cd ./Standalone && docker build $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:beta .

standalone_chrome: chrome
	cd ./Standalone && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:$(TAG_VERSION) .

standalone_chrome_dev: chrome_dev
	cd ./Standalone && docker build $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:dev .

standalone_chrome_beta: chrome_beta
	cd ./Standalone && docker build $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:beta .

standalone_edge: edge
	cd ./Standalone && docker build $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-edge -t $(NAME)/standalone-edge:$(TAG_VERSION) .

standalone_edge_dev: edge_dev
	cd ./Standalone && docker build $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-edge -t $(NAME)/standalone-edge:dev .

standalone_edge_beta: edge_beta
	cd ./Standalone && docker build $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-edge -t $(NAME)/standalone-edge:beta .

video:
	cd ./Video && docker build $(BUILD_ARGS) --build-arg NAMESPACE=$(FFMPEG_BASED_NAME) --build-arg BASED_TAG=$(FFMPEG_BASED_TAG) -t $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) .


# Register linux/arm64 and linux/arm/v7 architectures for building with BuildKit
# docker run --rm --privileged aptman/qus -s -- -p  # for actions
qemu_user_static:
	docker run --rm --privileged aptman/qus -- -r ; \
	docker run --rm --privileged aptman/qus -s -- -p

# Build multi-arch images
all_multi: base_multi \
	hub_multi \
	chromium_multi \
	firefox_multi \
	docker_multi \
	standalone_chromium_multi \
	standalone_firefox_multi \
	standalone_docker_multi \
	distributor_multi \
	router_multi \
	sessions_multi \
	sessionqueue_multi \
	event_bus_multi \
	video_multi

build_multi: all_multi

ci_multi: build_multi test_multi_arch

base_multi: qemu_user_static
	cd ./Base && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg VERSION=$(BASE_VERSION) --build-arg RELEASE=$(BASE_RELEASE) -t $(NAME)/base:$(TAG_VERSION) .

hub_multi: base_multi
	cd ./Hub && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/hub:$(TAG_VERSION) .

distributor_multi:
	cd ./Distributor && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/distributor:$(TAG_VERSION) .

router_multi:
	cd ./Router && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/router:$(TAG_VERSION) .

sessions_multi:
	cd ./Sessions && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/sessions:$(TAG_VERSION) .

sessionqueue_multi:
	cd ./SessionQueue && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/session-queue:$(TAG_VERSION) .

event_bus_multi: base_multi
	cd ./EventBus && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/event-bus:$(TAG_VERSION) .

node_base_multi: base_multi
	cd ./NodeBase && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-base:$(TAG_VERSION) .

chromium_multi: node_base_multi
	cd ./NodeChromium && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-chromium:$(TAG_VERSION) .

firefox_multi: node_base_multi
	cd ./NodeFirefox && docker buildx build -f Dockerfile.multi-arch --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-firefox:$(TAG_VERSION) .

docker_multi: base_multi
	cd ./NodeDocker && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-docker:$(TAG_VERSION) .

standalone_firefox_multi: firefox_multi
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:$(TAG_VERSION) .

standalone_chromium_multi: chromium_multi
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-chromium -t $(NAME)/standalone-chromium:$(TAG_VERSION) .

standalone_docker_multi: docker_multi
	cd ./StandaloneDocker && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/standalone-docker:$(TAG_VERSION) .

video_multi:
	cd ./Video && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(FFMPEG_BASED_NAME) --build-arg BASED_TAG=$(FFMPEG_BASED_TAG) -t $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) .

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

# Additional tags for browser images
tag_and_push_multi_arch_browser_images: tag_and_push_multi_arch_chromium_images tag_and_push_multi_arch_firefox_images

tag_and_push_multi_arch_chromium_images:
	./tag_and_push_multi-arch_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) chromium

tag_and_push_multi_arch_firefox_images:
	./tag_and_push_multi-arch_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) firefox

tag_major_minor_multi_arch:
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) base
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) hub
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) node-base
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) node-docker
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) standalone-docker
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) sessions
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) session-queue
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) event-bus
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) router
	./tag_and_push_multi-arch_major_minor.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) distributor

tag_multi_arch_latest:
	docker buildx imagetools create -t ${NAMESPACE}/base:latest ${NAMESPACE}/base:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/hub:latest ${NAMESPACE}/hub:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/node-base:latest ${NAMESPACE}/node-base:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/node-chromium:latest ${NAMESPACE}/node-chromium:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/node-firefox:latest ${NAMESPACE}/node-firefox:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/standalone-chromium:latest ${NAMESPACE}/standalone-chromium:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/standalone-firefox:latest ${NAMESPACE}/standalone-firefox:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/node-docker:latest ${NAMESPACE}/node-docker:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/standalone-docker:latest ${NAMESPACE}/standalone-docker:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/sessions:latest ${NAMESPACE}/sessions:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/session-queue:latest ${NAMESPACE}/session-queue:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/event-bus:latest ${NAMESPACE}/event-bus:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/router:latest ${NAMESPACE}/router:${TAG_VERSION}
	docker buildx imagetools create -t ${NAMESPACE}/distributor:latest ${NAMESPACE}/distributor:${TAG_VERSION}

	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) base latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) hub latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) node-base latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) node-chromium latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) node-firefox latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) standalone-chromium latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) standalone-firefox latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) node-docker latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) standalone-docker latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) sessions latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) session-queue latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) event-bus latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) router latest
	# ./tag-and-push-multi-arch-image.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) distributor latest

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
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChrome

test_chrome_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChrome

test_edge:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeEdge

test_edge_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneEdge

test_firefox:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefox

test_firefox_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefox

<<<<<<< HEAD

# Test multi-arch container images
test_multi_arch: test_chromium_multi \
 test_firefox_multi \
 test_chromium_standalone_multi \
 test_firefox_standalone_multi


test_chromium_multi:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChromium

test_chromium_standalone_multi:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChromium

test_firefox_multi:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefox

test_firefox_standalone_multi:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefox

=======
test_parallel: hub chrome firefox edge
	for node in DeploymentAutoscaling JobAutoscaling ; do \
			cd ./tests || true ; \
			echo TAG=$(TAG_VERSION) > .env ; \
			echo TEST_DRAIN_AFTER_SESSION_COUNT=$(or $(TEST_DRAIN_AFTER_SESSION_COUNT), 0) >> .env ; \
			echo TEST_PARALLEL_HARDENING=$(or $(TEST_PARALLEL_HARDENING), "false") >> .env ; \
			echo LOG_LEVEL=$(or $(LOG_LEVEL), "INFO") >> .env ; \
			echo REQUEST_TIMEOUT=$(or $(REQUEST_TIMEOUT), 300) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			docker-compose -f docker-compose-v3-test-parallel.yml up --no-log-prefix --exit-code-from tests --build ; \
	done
>>>>>>> origin/4.18.1

# This should run on its own CI job. There is no need to combine it with the other tests.
# Its main purpose is to check that a video file was generated.
test_video: video hub chrome firefox edge
	# Running a few tests with docker-compose to generate the videos
	rm -rf ./tests/videos; mkdir -p ./tests/videos
	for node in NodeChrome NodeFirefox NodeEdge ; do \
			cd ./tests || true ; \
			echo VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) > .env ; \
			echo TAG=$(TAG_VERSION) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			if [ $$node = "NodeChrome" ] ; then \
					echo BROWSER=chrome >> .env ; \
					echo VIDEO_FILE_NAME=chrome_video.mp4 >> .env ; \
			fi ; \
			if [ $$node = "NodeEdge" ] ; then \
					echo BROWSER=edge >> .env ; \
					echo VIDEO_FILE_NAME=edge_video.mp4 >> .env ; \
			fi ; \
			if [ $$node = "NodeFirefox" ] ; then \
					echo BROWSER=firefox >> .env ; \
					echo VIDEO_FILE_NAME=firefox_video.mp4 >> .env ; \
			fi ; \
			docker-compose -f docker-compose-v3-test-video.yml up --abort-on-container-exit --build ; \
	done
	# Using ffmpeg to verify file integrity
	# https://superuser.com/questions/100288/how-can-i-check-the-integrity-of-a-video-file-avi-mpeg-mp4
	docker run -u $$(id -u) -v $$(pwd):$$(pwd) -w $$(pwd) $(FFMPEG_BASED_NAME)/ffmpeg:$(FFMPEG_BASED_TAG) -v error -i ./tests/videos/chrome_video.mp4 -f null - 2>error.log
	docker run -u $$(id -u) -v $$(pwd):$$(pwd) -w $$(pwd) $(FFMPEG_BASED_NAME)/ffmpeg:$(FFMPEG_BASED_TAG) -v error -i ./tests/videos/firefox_video.mp4 -f null - 2>error.log
	docker run -u $$(id -u) -v $$(pwd):$$(pwd) -w $$(pwd) $(FFMPEG_BASED_NAME)/ffmpeg:$(FFMPEG_BASED_TAG) -v error -i ./tests/videos/edge_video.mp4 -f null - 2>error.log

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

chart_test_template:
	./tests/charts/bootstrap.sh

chart_test_chrome:
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
	./tests/charts/make/chart_test.sh NodeChrome

chart_test_firefox:
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
	./tests/charts/make/chart_test.sh NodeFirefox

chart_test_edge:
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
	./tests/charts/make/chart_test.sh NodeEdge

chart_test_autoscaling_deployment_https:
	CHART_FULL_DISTRIBUTED_MODE=true CHART_ENABLE_INGRESS_HOSTNAME=true CHART_ENABLE_BASIC_AUTH=true SELENIUM_GRID_PROTOCOL=https SELENIUM_GRID_PORT=443 \
	SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=1 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
	./tests/charts/make/chart_test.sh DeploymentAutoscaling

chart_test_autoscaling_deployment:
	CHART_ENABLE_TRACING=true SELENIUM_GRID_TEST_HEADLESS=true SELENIUM_GRID_HOST=$$(hostname -i) RELEASE_NAME=selenium \
	SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=1 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
	./tests/charts/make/chart_test.sh DeploymentAutoscaling

chart_test_autoscaling_job_https:
	SELENIUM_GRID_TEST_HEADLESS=true SELENIUM_GRID_PROTOCOL=https CHART_ENABLE_BASIC_AUTH=true RELEASE_NAME=selenium SELENIUM_GRID_PORT=443 SUB_PATH=/ \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
	./tests/charts/make/chart_test.sh JobAutoscaling

chart_test_autoscaling_job_hostname:
	CHART_ENABLE_TRACING=true CHART_ENABLE_INGRESS_HOSTNAME=true CHART_ENABLE_BASIC_AUTH=true \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
	./tests/charts/make/chart_test.sh JobAutoscaling

chart_test_autoscaling_job:
	CHART_ENABLE_TRACING=true CHART_FULL_DISTRIBUTED_MODE=true CHART_ENABLE_INGRESS_HOSTNAME=true SELENIUM_GRID_HOST=selenium-grid.local RELEASE_NAME=selenium SUB_PATH=/ \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) \
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
