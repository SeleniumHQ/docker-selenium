NAME := $(or $(NAME),$(NAME),selenium)
CURRENT_DATE := $(shell date '+%Y%m%d')
BUILD_DATE := $(or $(BUILD_DATE),$(BUILD_DATE),$(CURRENT_DATE))
BASE_RELEASE := $(or $(BASE_RELEASE),$(BASE_RELEASE),selenium-4.24.0)
BASE_VERSION := $(or $(BASE_VERSION),$(BASE_VERSION),4.24.0)
BINDING_VERSION := $(or $(BINDING_VERSION),$(BINDING_VERSION),4.24.0)
BASE_RELEASE_NIGHTLY := $(or $(BASE_RELEASE_NIGHTLY),$(BASE_RELEASE_NIGHTLY),nightly)
BASE_VERSION_NIGHTLY := $(or $(BASE_VERSION_NIGHTLY),$(BASE_VERSION_NIGHTLY),4.25.0-SNAPSHOT)
VERSION := $(or $(VERSION),$(VERSION),4.24.0)
TAG_VERSION := $(VERSION)-$(BUILD_DATE)
CHART_VERSION_NIGHTLY := $(or $(CHART_VERSION_NIGHTLY),$(CHART_VERSION_NIGHTLY),1.0.0-nightly)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),$(AUTHORS),SeleniumHQ)
PUSH_IMAGE := $(or $(PUSH_IMAGE),$(PUSH_IMAGE),false)
FROM_IMAGE_ARGS := --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(TAG_VERSION) --build-arg AUTHORS=$(AUTHORS) --sbom=true --attest type=provenance,mode=max
BUILD_ARGS := $(BUILD_ARGS) --progress plain
MAJOR := $(word 1,$(subst ., ,$(TAG_VERSION)))
MINOR := $(word 2,$(subst ., ,$(TAG_VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(TAG_VERSION)))
FFMPEG_TAG_PREV_VERSION := $(or $(FFMPEG_TAG_PREV_VERSION),$(FFMPEG_TAG_PREV_VERSION),ffmpeg-7.0.2)
FFMPEG_TAG_VERSION := $(or $(FFMPEG_TAG_VERSION),$(FFMPEG_TAG_VERSION),ffmpeg-7.0.2)
FFMPEG_BASED_NAME := $(or $(FFMPEG_BASED_NAME),$(FFMPEG_BASED_NAME),linuxserver)
FFMPEG_BASED_TAG := $(or $(FFMPEG_BASED_TAG),$(FFMPEG_BASED_TAG),7.0.2)
CURRENT_PLATFORM := $(shell if [ `arch` = "aarch64" ]; then echo "linux/arm64"; else echo "linux/amd64"; fi)
PLATFORMS := $(or $(PLATFORMS),$(shell echo $$PLATFORMS),$(CURRENT_PLATFORM))
SEL_PASSWD := $(or $(SEL_PASSWD),$(SEL_PASSWD),secret)
CHROMIUM_VERSION := $(or $(CHROMIUM_VERSION),$(CHROMIUM_VERSION),latest)
SBOM_OUTPUT := $(or $(SBOM_OUTPUT),$(SBOM_OUTPUT),package_versions.txt)

all: hub \
	distributor \
	router \
	sessions \
	sessionqueue \
	event_bus \
	chrome \
	chromium \
	edge \
	firefox \
	docker \
	standalone_chrome \
	standalone_chromium \
	standalone_edge \
	standalone_firefox \
	standalone_docker \
	video

check_dev_env:
	./tests/charts/make/chart_check_env.sh

setup_dev_env:
	./tests/charts/make/chart_setup_env.sh ; \
  make set_containerd_image_store

set_containerd_image_store:
	sudo mkdir -p /etc/docker
	sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.bak || true
	echo "{\"features\":{\"containerd-snapshotter\": true, \"containerd\": true}, \"experimental\": true}" | sudo tee /etc/docker/daemon.json
	sudo systemctl restart docker
	sudo chmod 666 /var/run/docker.sock
	docker version -f '{{.Server.Experimental}}'
	docker info -f '{{ .DriverStatus }}'

format_shell_scripts:
	sudo apt-get update -qq ; \
  sudo apt-get install -yq shfmt ; \
  shfmt -l -w -d $${PWD}/*.sh $${PWD}/**/*.sh $$PWD/**.sh $$PWD/**/generate_** $$PWD/**/wrap_* ; \
  git diff --stat --exit-code ; \
  EXIT_CODE=$$? ; \
  if [ $$EXIT_CODE -ne 0 ]; then \
		echo "Some shell scripts are not formatted. Please run 'make format_shell_scripts' to format and update them." ; \
		exit $$EXIT_CODE ; \
	fi ; \
  exit $$EXIT_CODE

generate_readme_charts:
	if [ ! -f $$HOME/go/bin/helm-docs ] ; then \
		echo "helm-docs is not installed. Please install it or run 'make setup_dev_env' once." ; \
	else \
		$$HOME/go/bin/helm-docs --chart-search-root charts/selenium-grid --output-file CONFIGURATION.md --sort-values-order file ; \
	fi

lint_readme_charts: generate_readme_charts
	git diff --stat --exit-code ; \
	EXIT_CODE=$$? ; \
	if [ $$EXIT_CODE -ne 0 ]; then \
			echo "New changes in chart. Please run 'make generate_readme_charts' to update them." ; \
			exit $$EXIT_CODE ; \
	fi ; \
  exit $$EXIT_CODE

set_build_nightly:
	echo BASE_VERSION=$(BASE_VERSION_NIGHTLY) > .env ; \
	echo BASE_RELEASE=$(BASE_RELEASE_NIGHTLY) >> .env ;
	echo "Execute 'source .env' to set the environment variables"

set_build_multiarch:
	echo PLATFORMS="linux/amd64,linux/arm64" > .env ; \
	echo "Execute 'source .env' to set the environment variables"

build_nightly:
	BASE_VERSION=$(BASE_VERSION_NIGHTLY) BASE_RELEASE=$(BASE_RELEASE_NIGHTLY) make build

build: check_dev_env all
	docker images | grep $(NAME)

ci: build test

prepare_resources:
	rm -rf ./Base/configs/node && mkdir -p ./Base/configs/node && cp -r ./charts/selenium-grid/configs/node ./Base/configs

gen_certs:
	rm -rf ./Base/certs && cp -r ./charts/selenium-grid/certs ./Base
	./Base/certs/gen-cert-helper.sh -d ./Base/certs

base: prepare_resources gen_certs
	cd ./Base && SEL_PASSWD=$(SEL_PASSWD) docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg VERSION=$(BASE_VERSION) --build-arg RELEASE=$(BASE_RELEASE) --build-arg AUTHORS=$(AUTHORS) \
	--secret id=SEL_PASSWD --sbom=true --attest type=provenance,mode=max -t $(NAME)/base:$(TAG_VERSION) .

base_nightly:
	BASE_VERSION=$(BASE_VERSION_NIGHTLY) BASE_RELEASE=$(BASE_RELEASE_NIGHTLY) make base

hub: base
	cd ./Hub && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/hub:$(TAG_VERSION) .

distributor: base
	cd ./Distributor && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/distributor:$(TAG_VERSION) .

router: base
	cd ./Router && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/router:$(TAG_VERSION) .

sessions: base
	cd ./Sessions && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/sessions:$(TAG_VERSION) .

sessionqueue: base
	cd ./SessionQueue && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/session-queue:$(TAG_VERSION) .

event_bus: base
	cd ./EventBus && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/event-bus:$(TAG_VERSION) .

node_base: base
	cd ./NodeBase && SEL_PASSWD=$(SEL_PASSWD) docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --secret id=SEL_PASSWD -t $(NAME)/node-base:$(TAG_VERSION) .

chrome: node_base
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
      echo "Google Chrome is only supported on linux/amd64" \
      && cd ./NodeChrome && docker buildx build --platform linux/amd64 $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-chrome:$(TAG_VERSION) . \
      ;; \
    *) \
       echo "Google Chrome doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

chrome_dev:
	cd ./NodeChrome && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg CHROME_VERSION=google-chrome-unstable -t $(NAME)/node-chrome:dev .

chrome_beta:
	cd ./NodeChrome && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg CHROME_VERSION=google-chrome-beta -t $(NAME)/node-chrome:beta .

chromium: node_base
	cd ./NodeChromium && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg CHROMIUM_VERSION=$(CHROMIUM_VERSION) -t $(NAME)/node-chromium:$(TAG_VERSION) .

edge: node_base
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
      echo "Microsoft Edge is only supported on linux/amd64" \
      && cd ./NodeEdge && docker buildx build --platform linux/amd64 $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-edge:$(TAG_VERSION) . \
      ;; \
    *) \
       echo "Microsoft Edge doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

edge_dev:
	cd ./NodeEdge && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg EDGE_VERSION=microsoft-edge-dev -t $(NAME)/node-edge:dev .

edge_beta:
	cd ./NodeEdge && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg EDGE_VERSION=microsoft-edge-beta -t $(NAME)/node-edge:beta .

firefox: node_base
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-firefox:$(TAG_VERSION) .

firefox_dev:
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg FIREFOX_VERSION=nightly-latest -t $(NAME)/node-firefox:dev .

firefox_beta:
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg FIREFOX_VERSION=beta-latest -t $(NAME)/node-firefox:beta .

docker: base
	cd ./NodeDocker && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/node-docker:$(TAG_VERSION) .

standalone_docker: docker
	cd ./StandaloneDocker && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) -t $(NAME)/standalone-docker:$(TAG_VERSION) .

standalone_firefox: firefox
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:$(TAG_VERSION) .

standalone_firefox_dev: firefox_dev
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:dev .

standalone_firefox_beta: firefox_beta
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:beta .

standalone_chrome: chrome
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
			echo "Google Chrome is only supported on linux/amd64" \
			&& cd ./Standalone && docker buildx build --platform linux/amd64 $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:$(TAG_VERSION) . \
      ;; \
    *) \
       echo "Google Chrome doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

standalone_chrome_dev: chrome_dev
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:dev .

standalone_chrome_beta: chrome_beta
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:beta .

standalone_chromium: chromium
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-chromium -t $(NAME)/standalone-chromium:$(TAG_VERSION) .

standalone_edge: edge
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
      echo "Microsoft Edge is only supported on linux/amd64" \
      && cd ./Standalone && docker buildx build --platform linux/amd64 $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-edge -t $(NAME)/standalone-edge:$(TAG_VERSION) . \
      ;; \
    *) \
       echo "Microsoft Edge doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

standalone_edge_dev: edge_dev
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=dev --build-arg BASE=node-edge -t $(NAME)/standalone-edge:dev .

standalone_edge_beta: edge_beta
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAME) --build-arg VERSION=beta --build-arg BASE=node-edge -t $(NAME)/standalone-edge:beta .

video:
	cd ./Video && SEL_PASSWD=$(SEL_PASSWD) docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(FFMPEG_BASED_NAME) --build-arg BASED_TAG=$(FFMPEG_BASED_TAG) --secret id=SEL_PASSWD --sbom=true --attest type=provenance,mode=max -t $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) .

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
	docker history $(NAME)/node-chromium:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-edge:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-firefox:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/node-docker:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-chrome:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-chromium:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-edge:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-firefox:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/standalone-docker:$(TAG_VERSION) -q | wc -l
	docker history $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) -q | wc -l

chrome_upgrade_version:
	cd ./NodeChrome && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(VERSION) --build-arg AUTHORS=$(AUTHORS) -t $(NAME)/node-chrome:$(TAG_VERSION) .
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-chrome -t $(NAME)/standalone-chrome:$(TAG_VERSION) .
	docker run --rm $(NAME)/standalone-chrome:$(TAG_VERSION) /opt/selenium/selenium-server.jar info --version
	docker run --rm $(NAME)/standalone-chrome:$(TAG_VERSION) google-chrome --version
	docker run --rm $(NAME)/standalone-chrome:$(TAG_VERSION) chromedriver --version

firefox_upgrade_version:
	cd ./NodeFirefox && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(VERSION) --build-arg AUTHORS=$(AUTHORS) -t $(NAME)/node-firefox:$(TAG_VERSION) .
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-firefox -t $(NAME)/standalone-firefox:$(TAG_VERSION) .
	docker run --rm $(NAME)/standalone-firefox:$(TAG_VERSION) /opt/selenium/selenium-server.jar info --version
	docker run --rm $(NAME)/standalone-firefox:$(TAG_VERSION) firefox --version
	docker run --rm $(NAME)/standalone-firefox:$(TAG_VERSION) geckodriver --version

edge_upgrade_version:
	cd ./NodeEdge && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) --build-arg NAMESPACE=$(NAMESPACE) --build-arg VERSION=$(VERSION) --build-arg AUTHORS=$(AUTHORS) -t $(NAME)/node-edge:$(TAG_VERSION) .
	cd ./Standalone && docker buildx build --platform $(PLATFORMS) $(BUILD_ARGS) $(FROM_IMAGE_ARGS) --build-arg BASE=node-edge -t $(NAME)/standalone-edge:$(TAG_VERSION) .
	docker run --rm $(NAME)/standalone-edge:$(TAG_VERSION) /opt/selenium/selenium-server.jar info --version
	docker run --rm $(NAME)/standalone-edge:$(TAG_VERSION) microsoft-edge --version
	docker run --rm $(NAME)/standalone-edge:$(TAG_VERSION) msedgedriver --version

# https://github.com/SeleniumHQ/docker-selenium/issues/992
# Additional tags for browser images
tag_and_push_browser_images: tag_and_push_chrome_images tag_and_push_chromium_images tag_and_push_firefox_images tag_and_push_edge_images

tag_and_push_chrome_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) chrome

tag_and_push_chromium_images:
	./tag_and_push_browser_images.sh $(VERSION) $(BUILD_DATE) $(NAMESPACE) $(PUSH_IMAGE) chromium

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
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:latest
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:latest
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:latest
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:latest
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:latest
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
	docker push $(NAME)/node-chromium:latest
	docker push $(NAME)/node-edge:latest
	docker push $(NAME)/node-firefox:latest
	docker push $(NAME)/node-docker:latest
	docker push $(NAME)/standalone-chrome:latest
	docker push $(NAME)/standalone-chromium:latest
	docker push $(NAME)/standalone-edge:latest
	docker push $(NAME)/standalone-firefox:latest
	docker push $(NAME)/standalone-docker:latest
	docker push $(NAME)/video:latest

generate_latest_sbom:
	NAME=$(NAME) FILTER_IMAGE_TAG=latest OUTPUT_FILE=$(SBOM_OUTPUT) ./generate_sbom.sh

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
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:nightly
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:nightly
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:nightly
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:nightly
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:nightly
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:nightly
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
	docker push $(NAME)/node-chromium:nightly
	docker push $(NAME)/node-edge:nightly
	docker push $(NAME)/node-firefox:nightly
	docker push $(NAME)/node-docker:nightly
	docker push $(NAME)/standalone-chrome:nightly
	docker push $(NAME)/standalone-chromium:nightly
	docker push $(NAME)/standalone-edge:nightly
	docker push $(NAME)/standalone-firefox:nightly
	docker push $(NAME)/standalone-docker:nightly
	docker push $(NAME)/video:nightly

generate_nightly_sbom:
	NAME=$(NAME) FILTER_IMAGE_TAG=nightly OUTPUT_FILE=$(SBOM_OUTPUT) ./generate_sbom.sh

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
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:$(MAJOR)
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:$(MAJOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR)
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:$(MAJOR)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR)
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:$(MAJOR)
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
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:$(MAJOR).$(MINOR)
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
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-edge:$(TAG_VERSION) $(NAME)/node-edge:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-docker:$(TAG_VERSION) $(NAME)/node-docker:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome:$(TAG_VERSION) $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:$(MAJOR_MINOR_PATCH)
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
	@if ! docker images $(NAME)/node-chromium | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-chromium version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-edge | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-edge version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-firefox version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-docker | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/node-docker version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-chrome version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chromium | awk '{ print $$2 }' | grep -q -F $(TAG_VERSION); then echo "$(NAME)/standalone-chromium version $(TAG_VERSION) is not yet built. Please run 'make build'"; false; fi
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
	docker push $(NAME)/node-chromium:$(TAG_VERSION)
	docker push $(NAME)/node-edge:$(TAG_VERSION)
	docker push $(NAME)/node-firefox:$(TAG_VERSION)
	docker push $(NAME)/node-docker:$(TAG_VERSION)
	docker push $(NAME)/standalone-chrome:$(TAG_VERSION)
	docker push $(NAME)/standalone-chromium:$(TAG_VERSION)
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
	docker push $(NAME)/node-chromium:$(MAJOR)
	docker push $(NAME)/node-edge:$(MAJOR)
	docker push $(NAME)/node-firefox:$(MAJOR)
	docker push $(NAME)/node-docker:$(MAJOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR)
	docker push $(NAME)/standalone-chromium:$(MAJOR)
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
	docker push $(NAME)/node-chromium:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-edge:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-docker:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chromium:$(MAJOR).$(MINOR)
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
	docker push $(NAME)/node-chromium:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-edge:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-docker:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chromium:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-edge:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-docker:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE)

test: test_chrome \
 test_chrome_standalone \
 test_chromium \
 test_chromium_standalone \
 test_firefox \
 test_firefox_standalone \
 test_edge \
 test_edge_standalone

test_chrome:
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
			echo "Google Chrome is only supported on linux/amd64" \
			&& PLATFORMS=linux/amd64 VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true ./tests/bootstrap.sh NodeChrome \
      ;; \
    *) \
       echo "Google Chrome doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

test_chrome_standalone:
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
			echo "Google Chrome is only supported on linux/amd64" \
			&& PLATFORMS=linux/amd64 VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true ./tests/bootstrap.sh StandaloneChrome \
      ;; \
    *) \
       echo "Google Chrome doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

test_edge:
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
			echo "Microsoft Edge is only supported on linux/amd64" \
			&& PLATFORMS=linux/amd64 VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true ./tests/bootstrap.sh NodeEdge \
      ;; \
    *) \
       echo "Microsoft Edge doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

test_edge_standalone:
	case "$(PLATFORMS)" in \
    *linux/amd64*) \
			echo "Microsoft Edge is only supported on linux/amd64" \
			&& PLATFORMS=linux/amd64 VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true ./tests/bootstrap.sh StandaloneEdge \
      ;; \
    *) \
       echo "Microsoft Edge doesn't support platform $(PLATFORMS)" ; \
      ;; \
  esac

test_firefox_download_lang_packs:
	FIREFOX_VERSION=$$(curl -sk https://product-details.mozilla.org/1.0/firefox_versions.json | jq -r '.LATEST_FIREFOX_VERSION') ; \
	./NodeFirefox/get_lang_package.sh $$FIREFOX_VERSION ./tests/target/firefox_lang_packs

test_firefox: test_firefox_download_lang_packs
	PLATFORMS=$(PLATFORMS) VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true \
	TEST_FIREFOX_INSTALL_LANG_PACKAGE=true ./tests/bootstrap.sh NodeFirefox

test_firefox_standalone:
	PLATFORMS=$(PLATFORMS) VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true ./tests/bootstrap.sh StandaloneFirefox

test_chromium:
	PLATFORMS=$(PLATFORMS) VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true ./tests/bootstrap.sh NodeChromium

test_chromium_standalone:
	PLATFORMS=$(PLATFORMS) VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BASE_RELEASE=$(BASE_RELEASE) BASE_VERSION=$(BASE_VERSION) BINDING_VERSION=$(BINDING_VERSION) SKIP_BUILD=true ./tests/bootstrap.sh StandaloneChromium

test_parallel: hub chrome firefox edge chromium video
	sudo rm -rf ./tests/tests
	sudo rm -rf ./tests/videos; mkdir -p ./tests/videos
	sudo cp -r ./charts/selenium-grid/certs ./tests/videos
	for node in DeploymentAutoscaling JobAutoscaling ; do \
			cd ./tests || true ; \
			echo TAG=$(TAG_VERSION) > .env ; \
			echo VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) >> .env ; \
			echo TEST_DELAY_AFTER_TEST=$(or $(TEST_DELAY_AFTER_TEST), 2) >> .env ; \
			echo TEST_DRAIN_AFTER_SESSION_COUNT=$(or $(TEST_DRAIN_AFTER_SESSION_COUNT), 2) >> .env ; \
			echo TEST_PARALLEL_HARDENING=$(or $(TEST_PARALLEL_HARDENING), "true") >> .env ; \
			echo TEST_PARALLEL_COUNT=$(or $(TEST_PARALLEL_COUNT), 5) >> .env ; \
			echo HUB_CHECKS_INTERVAL=$(or $(HUB_CHECKS_INTERVAL), 45) >> .env ; \
			echo LOG_LEVEL=$(or $(LOG_LEVEL), "INFO") >> .env ; \
			echo REQUEST_TIMEOUT=$(or $(REQUEST_TIMEOUT), 600) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			if [ "$(PLATFORMS)" = "linux/amd64" ]; then \
					echo NODE_CHROME=chrome >> .env ; \
			else \
					echo NODE_CHROME=chromium >> .env ; \
			fi; \
			echo TEST_PLATFORMS=$(PLATFORMS) >> .env ; \
			echo SELENIUM_GRID_PROTOCOL=https >> .env ; \
			echo CHART_CERT_PATH=$$(readlink -f ./videos/certs/tls.crt) >> .env ; \
			export $$(cat .env | xargs) ; \
			DOCKER_DEFAULT_PLATFORM=$(PLATFORMS) docker compose --profile $(PLATFORMS) -f docker-compose-v3-test-parallel.yml up -d --remove-orphans --no-log-prefix ; \
			RUN_IN_DOCKER_COMPOSE=true bash ./bootstrap.sh $$node ; \
			docker compose -f docker-compose-v3-test-parallel.yml down ; \
	done
	make test_video_integrity

test_video_standalone: standalone_chrome standalone_chromium standalone_firefox standalone_edge
	DOCKER_COMPOSE_FILE=docker-compose-v3-test-standalone.yml TEST_DELAY_AFTER_TEST=2 HUB_CHECKS_INTERVAL=45 make test_video

test_video_dynamic_name:
	VIDEO_FILE_NAME=auto TEST_DELAY_AFTER_TEST=2 HUB_CHECKS_INTERVAL=45 TEST_ADD_CAPS_RECORD_VIDEO=false \
	make test_video

# This should run on its own CI job. There is no need to combine it with the other tests.
# Its main purpose is to check that a video file was generated.
test_video: video hub chrome firefox edge chromium
	sudo rm -rf ./tests/tests
	sudo rm -rf ./tests/videos; mkdir -p ./tests/videos/upload
	sudo chmod -R 777 ./tests/videos
	docker_compose_file=$(or $(DOCKER_COMPOSE_FILE), docker-compose-v3-test-video.yml) ; \
	list_of_tests_amd64=$(or $(LIST_OF_TESTS_AMD64), "NodeChrome NodeChromium NodeFirefox NodeEdge") ; \
	list_of_tests_arm64=$(or $(LIST_OF_TESTS_ARM64), "NodeFirefox NodeChromium") ; \
	TEST_FIREFOX_INSTALL_LANG_PACKAGE=$(or $(TEST_FIREFOX_INSTALL_LANG_PACKAGE), "true") ; \
	if [ "$${TEST_FIREFOX_INSTALL_LANG_PACKAGE}" = "true" ]; then \
		make test_firefox_download_lang_packs ; \
	fi ; \
	if [ "$(PLATFORMS)" = "linux/amd64" ]; then \
			list_nodes="$${list_of_tests_amd64}" ; \
	else \
			list_nodes="$${list_of_tests_arm64}" ; \
	fi; \
	for node in $${list_nodes}; do \
			cd ./tests || true ; \
			echo VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) > .env ; \
			echo TAG=$(TAG_VERSION) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			echo TEST_DELAY_AFTER_TEST=$(or $(TEST_DELAY_AFTER_TEST), 2) >> .env ; \
			echo HUB_CHECKS_INTERVAL=$(or $(HUB_CHECKS_INTERVAL), 45) >> .env ; \
			echo SELENIUM_ENABLE_MANAGED_DOWNLOADS=$(or $(SELENIUM_ENABLE_MANAGED_DOWNLOADS), "true") >> .env ; \
			echo TEST_FIREFOX_INSTALL_LANG_PACKAGE=$${TEST_FIREFOX_INSTALL_LANG_PACKAGE} >> .env ; \
			echo BASIC_AUTH_USERNAME=$(or $(BASIC_AUTH_USERNAME), "admin") >> .env ; \
			echo BASIC_AUTH_PASSWORD=$(or $(BASIC_AUTH_PASSWORD), "admin") >> .env ; \
			echo SUB_PATH=$(or $(SUB_PATH), "/selenium") >> .env ; \
			echo TEST_ADD_CAPS_RECORD_VIDEO=$(or $(TEST_ADD_CAPS_RECORD_VIDEO), "true") >> .env ; \
			if [ $$node = "NodeChrome" ] ; then \
					echo BROWSER=chrome >> .env ; \
					echo VIDEO_FILE_NAME=$${VIDEO_FILE_NAME:-"chrome_video.mp4"} >> .env ; \
					echo VIDEO_FILE_NAME_SUFFIX=$${VIDEO_FILE_NAME_SUFFIX:-"true"} >> .env ; \
			fi ; \
			if [ $$node = "NodeChromium" ] ; then \
					echo BROWSER=chromium >> .env ; \
					echo VIDEO_FILE_NAME=$${VIDEO_FILE_NAME:-"chromium_video.mp4"} >> .env ; \
					echo VIDEO_FILE_NAME_SUFFIX=$${VIDEO_FILE_NAME_SUFFIX:-"true"} >> .env ; \
					echo SELENIUM_GRID_TEST_HEADLESS=true >> .env ; \
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
			DOCKER_DEFAULT_PLATFORM=$(PLATFORMS) docker compose -f $${docker_compose_file} up --remove-orphans --build  --exit-code-from tests ; \
	done
	make test_video_integrity

test_node_relay: hub node_base standalone_firefox
	sudo rm -rf ./tests/tests ./tests/videos; mkdir -p ./tests/videos ; \
	if [ "$(PLATFORMS)" = "linux/amd64" ]; then \
			list_nodes="Android NodeFirefox" ; \
	else \
			list_nodes="NodeFirefox" ; \
	fi; \
	for node in $${list_nodes} ; do \
			cd ./tests || true ; \
			echo TAG=$(TAG_VERSION) > .env ; \
			echo NAMESPACE=$(NAME) >> .env ; \
			echo LOG_LEVEL=$(or $(LOG_LEVEL), "INFO") >> .env ; \
			echo REQUEST_TIMEOUT=$(or $(REQUEST_TIMEOUT), 300) >> .env ; \
			echo SESSION_TIMEOUT=$(or $(SESSION_TIMEOUT), 300) >> .env ; \
			echo ANDROID_BASED_NAME=$(or $(ANDROID_BASED_NAME),budtmo) >> .env ; \
			echo ANDROID_BASED_IMAGE=$(or $(ANDROID_BASED_IMAGE),docker-android) >> .env ; \
			echo ANDROID_BASED_TAG=$(or $(ANDROID_BASED_TAG),emulator_14.0) >> .env ; \
			echo ANDROID_PLATFORM_API=$(or $(ANDROID_PLATFORM_API),14) >> .env ; \
			echo TEST_DELAY_AFTER_TEST=$(or $(TEST_DELAY_AFTER_TEST), 0) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo TEST_NODE_RELAY=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			if [ $$node = "Android" ] ; then \
					echo BROWSER=firefox >> .env \
					&& echo BROWSER_NAME=firefox >> .env ; \
			fi ; \
			if [ $$node = "NodeChrome" ] ; then \
					echo BROWSER=chrome >> .env \
					&& BROWSER_NAMEchrome >> .env ; \
			fi ; \
			if [ $$node = "NodeChromium" ] ; then \
					echo BROWSER=chromium >> .env \
					&& echo BROWSER_NAME=chrome >> .env ; \
					echo SELENIUM_GRID_TEST_HEADLESS=true >> .env ; \
			fi ; \
			if [ $$node = "NodeEdge" ] ; then \
					echo BROWSER=edge >> .env \
					&& echo BROWSER_NAME=MicrosoftEdge >> .env ; \
			fi ; \
			if [ $$node = "NodeFirefox" ] ; then \
					echo BROWSER=firefox >> .env \
					&& echo BROWSER_NAME=firefox >> .env ; \
			fi ; \
			export $$(cat .env | xargs) ; \
			envsubst < relay_config.toml > ./videos/relay_config.toml ; \
			DOCKER_DEFAULT_PLATFORM=$(PLATFORMS) docker compose --profile $$node -f docker-compose-v3-test-node-relay.yml up --remove-orphans --no-log-prefix --build --exit-code-from tests ; \
			if [ $$? -ne 0 ]; then exit 1; fi ; \
	done

test_standalone_docker: standalone_docker
	DOCKER_COMPOSE_FILE=docker-compose-v3-test-standalone-docker.yaml CONFIG_FILE=standalone_docker_config.toml HUB_CHECKS_INTERVAL=45 \
	RECORD_STANDALONE=true GRID_URL=http://0.0.0.0:4444 LIST_OF_TESTS_AMD64="DeploymentAutoscaling" TEST_PARALLEL_HARDENING=true TEST_DELAY_AFTER_TEST=2 \
	SELENIUM_ENABLE_MANAGED_DOWNLOADS=true LOG_LEVEL=SEVERE SKIP_CHECK_DOWNLOADS_VOLUME=true make test_node_docker

test_node_docker: hub standalone_docker standalone_chrome standalone_firefox standalone_edge standalone_chromium video
	sudo rm -rf ./tests/tests
	sudo rm -rf ./tests/videos; mkdir -p ./tests/videos/Downloads; mkdir -p ./tests/videos/upload
	sudo chmod -R 777 ./tests/videos
	docker_compose_file=$(or $(DOCKER_COMPOSE_FILE), docker-compose-v3-test-node-docker.yaml) ; \
	config_file=$(or $(CONFIG_FILE), config.toml) ; \
	list_of_tests_amd64=$(or $(LIST_OF_TESTS_AMD64), "NodeChrome NodeChromium NodeFirefox NodeEdge") ; \
	list_of_tests_arm64=$(or $(LIST_OF_TESTS_ARM64), "NodeFirefox NodeChromium") ; \
	if [ "$(PLATFORMS)" = "linux/amd64" ]; then \
			list_nodes="$${list_of_tests_amd64}" ; \
	else \
			list_nodes="$${list_of_tests_arm64}" ; \
	fi; \
	for node in $${list_nodes} ; do \
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
			echo TEST_DELAY_AFTER_TEST=$(or $(TEST_DELAY_AFTER_TEST), 2) >> .env ; \
			echo RECORD_STANDALONE=$(or $(RECORD_STANDALONE), "true") >> .env ; \
			echo GRID_URL=$(or $(GRID_URL), "") >> .env ; \
			echo HUB_CHECKS_INTERVAL=$(or $(HUB_CHECKS_INTERVAL), 20) >> .env ; \
			echo NODE=$$node >> .env ; \
			echo UID=$$(id -u) >> .env ; \
			echo BINDING_VERSION=$(BINDING_VERSION) >> .env ; \
			echo HOST_IP=$$(hostname -I | awk '{print $$1}') >> .env ; \
			if [ "$(PLATFORMS)" = "linux/amd64" ]; then \
					NODE_EDGE=edge ; \
					NODE_CHROME=chrome ; \
			else \
					NODE_EDGE=chromium ; \
					NODE_CHROME=chromium ; \
			fi; \
			echo NODE_EDGE=$${NODE_EDGE} >> .env ; \
			if [ $$node = "NodeChrome" ] ; then \
					echo NODE_CHROME=$${NODE_CHROME} >> .env ; \
			fi ; \
			if [ $$node = "NodeChromium" ] ; then \
					echo NODE_CHROME=chromium >> .env ; \
					echo SELENIUM_GRID_TEST_HEADLESS=true >> .env ; \
			else \
					echo NODE_CHROME=$${NODE_CHROME} >> .env ; \
			fi ; \
			export $$(cat .env | xargs) ; \
			envsubst < $${config_file} > ./videos/config.toml ; \
			DOCKER_DEFAULT_PLATFORM=$(PLATFORMS) docker compose -f $${docker_compose_file} up --remove-orphans --no-log-prefix --build --exit-code-from tests ; \
			if [ $$? -ne 0 ]; then exit 1; fi ; \
			if [ "$$SKIP_CHECK_DOWNLOADS_VOLUME" != "true" ] && [ -d "$$DOWNLOADS_DIR" ] && [ $$(ls -1q $$DOWNLOADS_DIR | wc -l) -eq 0 ]; then \
					echo "Mounted downloads directory is empty. Downloaded files could not be retrieved!" ; \
					exit 1 ; \
			fi ; \
	done
	make test_video_integrity

test_custom_ca_cert:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/customCACert/bootstrap.sh

chart_cluster_setup:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) BUILD_DATE=$(BUILD_DATE) ./tests/charts/make/chart_cluster_setup.sh
	make set_containerd_image_store

chart_cluster_cleanup:
	./tests/charts/make/chart_cluster_cleanup.sh

chart_build_nightly:
	VERSION=$(CHART_VERSION_NIGHTLY) ./tests/charts/make/chart_build.sh

chart_build:
	VERSION=$(TAG_VERSION) ./tests/charts/make/chart_build.sh

chart_release:
	NAMESPACE=$(NAMESPACE) ./tests/charts/make/chart_release.sh

test_video_integrity:
	# Using ffmpeg to verify file integrity
	# https://superuser.com/questions/100288/how-can-i-check-the-integrity-of-a-video-file-avi-mpeg-mp4
	list_files=$$(find ./tests/videos -type f -name "*.mp4"); \
	echo "::warning:: Number of video files: $$(echo $$list_files | wc -w)"; \
	number_corrupted_files=0; \
	if [ -z "$$list_files" ]; then \
		echo "No video files found"; \
		exit 1; \
	fi; \
	for file in $$list_files; do \
		echo "Checking video file: $$file"; \
	  docker run -u $$(id -u) -v $$(pwd):$$(pwd) -w $$(pwd) --entrypoint="" $(NAME)/video:$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) ffmpeg -v error -i "$$file" -f null - ; \
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

chart_render_template:
	RENDER_HELM_TEMPLATE_ONLY=true make chart_test_autoscaling_disabled chart_test_autoscaling_deployment_https chart_test_autoscaling_deployment chart_test_autoscaling_job_https chart_test_autoscaling_job_hostname chart_test_autoscaling_job

chart_test_autoscaling_disabled:
	PLATFORMS=$(PLATFORMS) TEST_CHROMIUM=true RELEASE_NAME=selenium SELENIUM_GRID_AUTOSCALING=false CHART_ENABLE_TRACING=true \
	SECURE_INGRESS_ONLY_GENERATE=true SELENIUM_GRID_PROTOCOL=https SELENIUM_GRID_HOST=$$(hostname -i) SELENIUM_GRID_PORT=443 EXTERNAL_UPLOADER_CONFIG=true \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	TEMPLATE_OUTPUT_FILENAME="k8s_nodeChromium_enableTracing_secureIngress_generateCerts_ingressPublicIP_subPath.yaml" \
	./tests/charts/make/chart_test.sh NoAutoscaling

chart_test_autoscaling_deployment_https:
	PLATFORMS=$(PLATFORMS) CHART_FULL_DISTRIBUTED_MODE=true CHART_ENABLE_BASIC_AUTH=true \
	SECURE_INGRESS_ONLY_DEFAULT=true INGRESS_DISABLE_USE_HTTP2=true SELENIUM_GRID_PROTOCOL=https CHART_ENABLE_INGRESS_HOSTNAME=true SELENIUM_GRID_PORT=443 \
	SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=1 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	TEMPLATE_OUTPUT_FILENAME="k8s_fullDistributed_basicAuth_secureIngress_defaultCerts_ingressHostName_disableHttp2_autoScaling_scaledObject_subPath.yaml" \
	./tests/charts/make/chart_test.sh DeploymentAutoscaling

chart_test_autoscaling_deployment:
	PLATFORMS=$(PLATFORMS) TEST_EXISTING_KEDA=true RELEASE_NAME=selenium CHART_ENABLE_TRACING=true \
	SECURE_CONNECTION_SERVER=true SECURE_USE_EXTERNAL_CERT=true SERVICE_TYPE_NODEPORT=true SELENIUM_GRID_PROTOCOL=https SELENIUM_GRID_HOST=$$(hostname -i) SELENIUM_GRID_PORT=31444 \
	SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=1 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	TEMPLATE_OUTPUT_FILENAME="k8s_prefixSelenium_enableTracing_secureServer_externalCerts_nodePort_autoScaling_scaledObject_existingKEDA_subPath.yaml" \
	./tests/charts/make/chart_test.sh DeploymentAutoscaling

chart_test_autoscaling_job_https:
	PLATFORMS=$(PLATFORMS) TEST_EXISTING_KEDA=true RELEASE_NAME=selenium CHART_ENABLE_BASIC_AUTH=true \
	SECURE_CONNECTION_SERVER=true SELENIUM_GRID_PROTOCOL=https SELENIUM_GRID_PORT=443 SUB_PATH=/ \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) EXTERNAL_UPLOADER_CONFIG=true \
	TEMPLATE_OUTPUT_FILENAME="k8s_prefixSelenium_basicAuth_secureServer_autoScaling_scaledJob_existingKEDA.yaml" \
	./tests/charts/make/chart_test.sh JobAutoscaling

chart_test_autoscaling_job_hostname:
	PLATFORMS=$(PLATFORMS) CHART_ENABLE_TRACING=true CHART_ENABLE_BASIC_AUTH=true \
	SECURE_INGRESS_ONLY_DEFAULT=true SECURE_USE_EXTERNAL_CERT=true SELENIUM_GRID_PROTOCOL=https SELENIUM_GRID_HOST=$$(hostname -i) SELENIUM_GRID_PORT=443 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	TEMPLATE_OUTPUT_FILENAME="k8s_enableTracing_basicAuth_secureIngress_externalCerts_ingressPublicIP_autoScaling_scaledJob_subPath.yaml" \
	./tests/charts/make/chart_test.sh JobAutoscaling

chart_test_autoscaling_job:
	PLATFORMS=$(PLATFORMS) TEST_EXISTING_KEDA=true TEST_CHROMIUM=true RELEASE_NAME=selenium CHART_ENABLE_TRACING=true CHART_FULL_DISTRIBUTED_MODE=true \
	SECURE_INGRESS_ONLY_CONFIG_INLINE=true SECURE_USE_EXTERNAL_CERT=true CHART_ENABLE_INGRESS_HOSTNAME=true SELENIUM_GRID_PROTOCOL=https SELENIUM_GRID_HOST=selenium-grid.prod SUB_PATH=/ SELENIUM_GRID_PORT=443 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	TEMPLATE_OUTPUT_FILENAME="k8s_fullDistributed_secureIngress_externalCerts_ingressHostName_ingressTLSInline_autoScaling_scaledJob_existingKEDA_prefixSelenium_nodeChromium_enableTracing.yaml" \
	./tests/charts/make/chart_test.sh JobAutoscaling

chart_test_language_bindings:
	PLATFORMS=$(PLATFORMS) \
	SELENIUM_GRID_HOST=$$(hostname -i) \
	SELENIUM_GRID_AUTOSCALING_MIN_REPLICA=1 \
	VERSION=$(TAG_VERSION) VIDEO_TAG=$(FFMPEG_TAG_VERSION)-$(BUILD_DATE) NAMESPACE=$(NAMESPACE) BINDING_VERSION=$(BINDING_VERSION) \
	./tests/charts/make/chart_test.sh DeploymentAutoscaling

.PHONY: \
	all \
	base \
	build \
	ci \
	chrome \
	chromium \
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
	standalone_chromium \
	standalone_edge \
	standalone_firefox \
	standalone_docker \
	tag_latest \
	tag_and_push_browser_images \
	test \
	video
