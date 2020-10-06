NAME := $(or $(NAME),$(NAME),selenium)
CURRENT_DATE := $(shell date '+%Y%m%d')
BUILD_DATE := $(or $(BUILD_DATE),$(BUILD_DATE),$(CURRENT_DATE))
VERSION := $(or $(VERSION),$(VERSION),4.0.0-alpha-7)
TAG_VERSION := $(VERSION)-$(BUILD_DATE)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),$(AUTHORS),SeleniumHQ)
PUSH_IMAGE := $(or $(PUSH_IMAGE),$(PUSH_IMAGE),false)
BUILD_ARGS := $(BUILD_ARGS)
MAJOR := $(word 1,$(subst ., ,$(TAG_VERSION)))
MINOR := $(word 2,$(subst ., ,$(TAG_VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(TAG_VERSION)))
FFMPEG_TAG_VERSION := $(or $(FFMPEG_TAG_VERSION),$(FFMPEG_TAG_VERSION),ffmpeg-4.3.1)

all: hub \
	distributor \
	router \
	sessions \
	event_bus \
	chrome \
	firefox \
	opera \
	standalone_chrome \
	standalone_firefox \
	standalone_opera \
	video

generate_all:	\
	generate_hub \
	generate_distributor \
	generate_router \
	generate_sessions \
	generate_event_bus \
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
	cd ./Base && docker build $(BUILD_ARGS) -t $(NAME)/base:$(TAG_VERSION) .

generate_hub:
	cd ./Hub && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

hub: base generate_hub
	cd ./Hub && docker build $(BUILD_ARGS) -t $(NAME)/hub:$(TAG_VERSION) .

generate_distributor:
	cd ./Distributor && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

distributor: base generate_distributor
	cd ./Distributor && docker build $(BUILD_ARGS) -t $(NAME)/distributor:$(TAG_VERSION) .

generate_router:
	cd ./Router && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

router: base generate_router
	cd ./Router && docker build $(BUILD_ARGS) -t $(NAME)/router:$(TAG_VERSION) .

generate_sessions:
	cd ./Sessions && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

sessions: base generate_sessions
	cd ./Sessions && docker build $(BUILD_ARGS) -t $(NAME)/sessions:$(TAG_VERSION) .

generate_event_bus:
	cd ./EventBus && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

event_bus: base generate_event_bus
	cd ./EventBus && docker build $(BUILD_ARGS) -t $(NAME)/event-bus:$(TAG_VERSION) .

generate_node_base:
	cd ./NodeBase && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

node_base: base generate_node_base
	cd ./NodeBase && docker build $(BUILD_ARGS) -t $(NAME)/node-base:$(TAG_VERSION) .

generate_chrome:
	cd ./NodeChrome && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

chrome: node_base generate_chrome
	cd ./NodeChrome && docker build $(BUILD_ARGS) -t $(NAME)/node-chrome:$(TAG_VERSION) .

generate_firefox:
	cd ./NodeFirefox && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

firefox: node_base generate_firefox
	cd ./NodeFirefox && docker build $(BUILD_ARGS) -t $(NAME)/node-firefox:$(TAG_VERSION) .

generate_opera:
	cd ./NodeOpera && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

opera: node_base generate_opera
	cd ./NodeOpera && docker build $(BUILD_ARGS) -t $(NAME)/node-opera:$(TAG_VERSION) .

generate_standalone_firefox:
	cd ./Standalone && ./generate.sh StandaloneFirefox node-firefox Firefox $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox: firefox generate_standalone_firefox
	cd ./StandaloneFirefox && docker build $(BUILD_ARGS) -t $(NAME)/standalone-firefox:$(TAG_VERSION) .

generate_standalone_chrome:
	cd ./Standalone && ./generate.sh StandaloneChrome node-chrome Chrome $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome: chrome generate_standalone_chrome
	cd ./StandaloneChrome && docker build $(BUILD_ARGS) -t $(NAME)/standalone-chrome:$(TAG_VERSION) .

generate_standalone_opera:
	cd ./Standalone && ./generate.sh StandaloneOpera node-opera Opera $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

standalone_opera: opera generate_standalone_opera
	cd ./StandaloneOpera && docker build $(BUILD_ARGS) -t $(NAME)/standalone-opera:$(TAG_VERSION) .

video:
	cd ./Video && docker build $(BUILD_ARGS) -t $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) .


# https://github.com/SeleniumHQ/docker-selenium/issues/992
# Additional tags for browser images
tag_and_push_browser_images: tag_and_push_chrome_images tag_and_push_firefox_images tag_and_push_opera_images

tag_and_push_chrome_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) chrome

tag_and_push_firefox_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) firefox

tag_and_push_opera_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) opera

tag_latest:
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:latest
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:latest
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:latest
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:latest
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:latest
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:latest
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:latest
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/node-opera:$(TAG_VERSION) $(NAME)/node-opera:latest
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:latest
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:latest
	docker tag $(NAME)/standalone-opera:$(TAG_VERSION) $(NAME)/standalone-opera:latest

release_latest:
	docker push $(NAME)/base:latest
	docker push $(NAME)/hub:latest
	docker push $(NAME)/distributor:latest
	docker push $(NAME)/router:latest
	docker push $(NAME)/sessions:latest
	docker push $(NAME)/event-bus:latest
	docker push $(NAME)/node-base:latest
	docker push $(NAME)/node-chrome:latest
	docker push $(NAME)/node-firefox:latest
	docker push $(NAME)/node-opera:latest
	docker push $(NAME)/standalone-chrome:latest
	docker push $(NAME)/standalone-firefox:latest
	docker push $(NAME)/standalone-opera:latest

tag_major_minor:
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR)
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:$(MAJOR)
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:$(MAJOR)
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:$(MAJOR)
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:$(MAJOR)
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:$(MAJOR)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR)
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:$(MAJOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR)
	docker tag $(NAME)/node-opera:$(TAG_VERSION) $(NAME)/node-opera:$(MAJOR)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR)
	docker tag $(NAME)/standalone-opera:$(TAG_VERSION) $(NAME)/standalone-opera:$(MAJOR)
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:$(MAJOR).$(MINOR)
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:$(MAJOR).$(MINOR)
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:$(MAJOR).$(MINOR)
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:$(MAJOR).$(MINOR)
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-opera:$(TAG_VERSION) $(NAME)/node-opera:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-opera:$(TAG_VERSION) $(NAME)/standalone-opera:$(MAJOR).$(MINOR)
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/hub:$(TAG_VERSION) $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/distributor:$(TAG_VERSION) $(NAME)/distributor:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/router:$(TAG_VERSION) $(NAME)/router:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/sessions:$(TAG_VERSION) $(NAME)/sessions:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/event-bus:$(TAG_VERSION) $(NAME)/event-bus:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chrome:$(TAG_VERSION) $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-opera:$(TAG_VERSION) $(NAME)/node-opera:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-opera:$(TAG_VERSION) $(NAME)/standalone-opera:$(MAJOR_MINOR_PATCH)

release: tag_major_minor
	@if ! docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/base version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/hub | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/hub version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/distributor | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/distributor version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/router | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/router version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/sessions | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/sessions version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/event-bus | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/event-bus version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-base | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-base version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-chrome version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-firefox version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-opera | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-opera version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-chrome version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-firefox version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-opera | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-opera version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/base:$(TAG_VERSION)
	docker push $(NAME)/hub:$(TAG_VERSION)
	docker push $(NAME)/distributor:$(TAG_VERSION)
	docker push $(NAME)/router:$(TAG_VERSION)
	docker push $(NAME)/sessions:$(TAG_VERSION)
	docker push $(NAME)/event-bus:$(TAG_VERSION)
	docker push $(NAME)/node-base:$(TAG_VERSION)
	docker push $(NAME)/node-chrome:$(TAG_VERSION)
	docker push $(NAME)/node-firefox:$(TAG_VERSION)
	docker push $(NAME)/node-opera:$(TAG_VERSION)
	docker push $(NAME)/standalone-chrome:$(TAG_VERSION)
	docker push $(NAME)/standalone-firefox:$(TAG_VERSION)
	docker push $(NAME)/standalone-opera:$(TAG_VERSION)
	docker push $(NAME)/base:$(MAJOR)
	docker push $(NAME)/hub:$(MAJOR)
	docker push $(NAME)/distributor:$(MAJOR)
	docker push $(NAME)/router:$(MAJOR)
	docker push $(NAME)/sessions:$(MAJOR)
	docker push $(NAME)/event-bus:$(MAJOR)
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
	docker push $(NAME)/event-bus:$(MAJOR).$(MINOR)
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
	docker push $(NAME)/event-bus:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-opera:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-opera:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE)

test: test_chrome \
 test_firefox \
 test_opera \
 test_chrome_standalone \
 test_firefox_standalone \
 test_opera_standalone


test_chrome:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChrome

test_chrome_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChrome

test_firefox:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefox

test_firefox_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefox

test_opera:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeOpera

test_opera_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneOpera

# This should run on its own CI job. There is no need to combine it with the other tests.
# Its main purpose is to check that a video file was generated.
test_video: video hub chrome firefox opera
	# Running a few tests with docker-compose to generate the videos
	for node in NodeChrome NodeFirefox NodeOpera ; do \
			cd ./tests || true ; \
			echo VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) > .env ; \
			echo TAG=$(TAG_VERSION) >> .env ; \
			echo NODE=$$node >> .env ; \
			if [ $$node = "NodeChrome" ] ; then \
					echo BROWSER=chrome >> .env ; \
					echo VIDEO_FILE_NAME=chrome_video.mp4 >> .env ; \
			fi ; \
			if [ $$node = "NodeFirefox" ] ; then \
					echo BROWSER=firefox >> .env ; \
					echo VIDEO_FILE_NAME=firefox_video.mp4 >> .env ; \
			fi ; \
			if [ $$node = "NodeOpera" ] ; then \
					echo BROWSER=opera >> .env ; \
					echo VIDEO_FILE_NAME=opera_video.mp4 >> .env ; \
			fi ; \
			docker-compose -f docker-compose-v3-test-video.yml up --abort-on-container-exit --build ; \
	done
	# Using ffmpeg to verify file integrity
	# https://superuser.com/questions/100288/how-can-i-check-the-integrity-of-a-video-file-avi-mpeg-mp4
	docker run -v $$(pwd):$$(pwd) -w $$(pwd) jrottenberg/ffmpeg:4.3.1-ubuntu1804 -v error -i ./tests/videos/chrome_video.mp4 -f null - 2>error.log
	docker run -v $$(pwd):$$(pwd) -w $$(pwd) jrottenberg/ffmpeg:4.3.1-ubuntu1804 -v error -i ./tests/videos/firefox_video.mp4 -f null - 2>error.log
	docker run -v $$(pwd):$$(pwd) -w $$(pwd) jrottenberg/ffmpeg:4.3.1-ubuntu1804 -v error -i ./tests/videos/opera_video.mp4 -f null - 2>error.log

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
	generate_event_bus \
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
	event_bus \
	node_base \
	release \
	standalone_chrome \
	standalone_firefox \
	tag_latest \
	tag_and_push_browser_images \
	test \
	video
