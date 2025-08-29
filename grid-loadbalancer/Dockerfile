FROM golang:1.21-alpine AS builder

# Set working directory
WORKDIR /app

# Install git and ca-certificates (needed for go mod download)
RUN apk add --no-cache git ca-certificates

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o selenium-grid-lb main.go

# Final stage
FROM alpine:latest

# Install ca-certificates and curl for health checks
RUN apk --no-cache add ca-certificates curl

# Create app directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/selenium-grid-lb .

# Copy configuration file
COPY --from=builder /app/config.yaml .

# Create non-root user
RUN adduser -D -s /bin/sh appuser
USER appuser

# Expose ports
EXPOSE 4444 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4444/lb/health || exit 1

# Run the application
CMD ["./selenium-grid-lb", "-config", "config.yaml"]
