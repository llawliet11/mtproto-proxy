# Use Alpine Linux as base image
FROM alpine:latest

# Install only essential runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/*

# Download pre-built mtg binary from GitHub releases
ARG MTG_VERSION=2.1.7
RUN echo "Downloading mtg v${MTG_VERSION}..." \
    && curl -L --max-time 30 --retry 3 -o mtg.tar.gz \
       "https://github.com/9seconds/mtg/releases/download/v${MTG_VERSION}/mtg-${MTG_VERSION}-linux-amd64.tar.gz" \
    && echo "Download completed, extracting..." \
    && tar -xzf mtg.tar.gz \
    && mv mtg-${MTG_VERSION}-linux-amd64/mtg /usr/local/bin/mtg \
    && chmod +x /usr/local/bin/mtg \
    && rm -rf mtg.tar.gz mtg-${MTG_VERSION}-linux-amd64/ \
    && echo "Testing mtg binary..." \
    && mtg --version \
    && echo "mtg installation completed successfully"

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
