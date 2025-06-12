# Use Alpine Linux as base image
FROM alpine:latest

# Install runtime dependencies and build tools
RUN apk add --no-cache \
    ca-certificates \
    curl \
    wget \
    tzdata \
    tar \
    && update-ca-certificates

# Download pre-built mtg binary from GitHub releases
ARG MTG_VERSION=v2.1.7
RUN wget -O mtg.tar.gz "https://github.com/9seconds/mtg/releases/download/${MTG_VERSION}/mtg-${MTG_VERSION}-linux-amd64.tar.gz" \
    && tar -xzf mtg.tar.gz \
    && mv mtg /usr/local/bin/mtg \
    && chmod +x /usr/local/bin/mtg \
    && rm mtg.tar.gz \
    && mtg --version

# Create non-root user for security
RUN addgroup -g 1000 mtg && \
    adduser -D -s /bin/sh -u 1000 -G mtg mtg

# Set working directory
WORKDIR /app

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
