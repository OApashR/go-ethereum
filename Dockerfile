# syntax=docker/dockerfile:1.4

# Optional build arguments for metadata
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

# Use an explicit version for reproducibility
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev linux-headers git

# Set working directory
WORKDIR /go-ethereum

# Copy go.mod and go.sum first for better layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build geth binary statically
RUN go run build/ci.go install -static ./cmd/geth

# Final minimal image
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Copy geth binary from builder
COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/geth

# Expose common Ethereum ports
EXPOSE 8545 8546 30303 30303/udp

# Metadata labels
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""
LABEL org.opencontainers.image.source="https://github.com/YOUR_GITHUB_REPO" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.build_number="${BUILDNUM}"

# Default entrypoint
ENTRYPOINT ["geth"]
