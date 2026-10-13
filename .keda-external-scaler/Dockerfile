# syntax=docker/dockerfile:1

# Build stage. TARGETOS/TARGETARCH are provided by buildx for multi-arch builds.
FROM --platform=$BUILDPLATFORM golang:1.27 AS build
ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

# Cache modules separately from source.
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/selenium-grid-scaler ./cmd/scaler

# Runtime stage: distroless static, non-root.
FROM gcr.io/distroless/static:nonroot
# Standard Selenium Grid image build args (passed by the root Makefile like other components).
ARG NAMESPACE
ARG VERSION
ARG AUTHORS
LABEL authors=${AUTHORS}
LABEL version=${VERSION}
COPY --from=build /out/selenium-grid-scaler /usr/local/bin/selenium-grid-scaler
EXPOSE 8080
# Numeric uid/gid (distroless "nonroot" = 65532) so Kubernetes runAsNonRoot can
# verify the user without a non-numeric-user CreateContainerConfigError.
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/selenium-grid-scaler"]
