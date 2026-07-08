# Build stage
FROM golang:1.26.4-alpine AS builder

# Set destination for COPY
WORKDIR /app

# Download Go modules
COPY headscale/go.mod headscale/go.sum ./
RUN go mod download

# Copy the source code
COPY headscale/ .

# Build
RUN CGO_ENABLED=0 go build -o /app/headscale ./cmd/headscale

# Runtime stage
FROM alpine:3.21
# Install necessary packages
RUN apk --no-cache add ca-certificates

# Non-root user to run headscale as
RUN addgroup -S headscale && adduser -S headscale -G headscale

# Matches the paths config.production.yaml stores the noise key, DERP key, and sqlite db under,
# plus the directory for headscale's local control unix socket.
RUN mkdir -p /var/lib/headscale /var/run/headscale \
    && chown -R headscale:headscale /var/lib/headscale /var/run/headscale
VOLUME /var/lib/headscale

COPY --from=builder /app/headscale /usr/local/bin/headscale
COPY config.production.yaml /etc/headscale/config.yaml

USER headscale

# HTTP (control plane API, used by Tailscale clients)
EXPOSE 8080/tcp

CMD ["headscale", "serve"]
# trigger full pipeline for screenshot
