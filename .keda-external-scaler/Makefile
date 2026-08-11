# Makefile for the Selenium Grid KEDA external scaler.

MODULE      := github.com/SeleniumHQ/docker-selenium/keda-external-scaler
BIN_DIR     := bin
BINARY      := $(BIN_DIR)/selenium-grid-scaler
IMAGE       ?= selenium/keda-external-scaler
TAG         ?= local
PLATFORMS   ?= linux/amd64,linux/arm64

# Pinned codegen plugin versions. Generated code is committed, so `make proto`
# is only needed when the vendored proto changes.
PROTOC_GEN_GO_VERSION      := v1.36.5
PROTOC_GEN_GO_GRPC_VERSION := v1.5.1

.PHONY: all
all: build

.PHONY: tidy
tidy:
	go mod tidy

.PHONY: build
build:
	CGO_ENABLED=0 go build -o $(BINARY) ./cmd/scaler

.PHONY: test
test:
	go test ./... -race -cover

.PHONY: vet
vet:
	go vet ./...

.PHONY: lint
lint:
	golangci-lint run

.PHONY: proto-tools
proto-tools:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@$(PROTOC_GEN_GO_VERSION)
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@$(PROTOC_GEN_GO_GRPC_VERSION)

# Regenerate gRPC stubs from the vendored proto. Requires protoc on PATH.
.PHONY: proto
proto:
	protoc -I proto \
		--go_out=externalscaler --go_opt=paths=source_relative \
		--go-grpc_out=externalscaler --go-grpc_opt=paths=source_relative \
		proto/externalscaler.proto

.PHONY: image
image:
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE):$(TAG) .

.PHONY: image-load
image-load:
	docker buildx build --load -t $(IMAGE):$(TAG) .

.PHONY: clean
clean:
	rm -rf $(BIN_DIR)
