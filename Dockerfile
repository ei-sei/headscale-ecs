# Build stage
FROM golang:1.26.3-alpine AS builder

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
RUN mkdir -p /data
VOLUME /data

COPY --from=builder /app/headscale /usr/local/bin/headscale

# HTTP (control plane API, used by Tailscale clients)
EXPOSE 8080/tcp

# gRPC (used by headscale CLI to talk to the server)
EXPOSE 50443/tcp

# WireGuard (the actual VPN tunnel traffic)
EXPOSE 41641/udp

CMD ["headscale", "serve"]

#trigger deploy test
