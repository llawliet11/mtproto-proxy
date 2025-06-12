# Multi-stage build for optimal image size
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /build

# Clone the mtg repository
RUN git clone https://github.com/9seconds/mtg.git .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o mtg ./cmd/mtg

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates curl tzdata && \
    addgroup -g 1000 mtg && \
    adduser -D -s /bin/sh -u 1000 -G mtg mtg

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /build/mtg /usr/local/bin/mtg

# Create necessary directories
RUN mkdir -p /app/logs /app/config && \
    chown -R mtg:mtg /app

# Copy configuration files
COPY scripts/entrypoint.sh /app/entrypoint.sh
COPY scripts/healthcheck.sh /app/healthcheck.sh

# Make scripts executable
RUN chmod +x /app/entrypoint.sh /app/healthcheck.sh

# Switch to non-root user
USER mtg

# Expose ports
EXPOSE 8443 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /app/healthcheck.sh

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command
CMD ["mtg"]
