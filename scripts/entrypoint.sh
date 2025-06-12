#!/bin/sh

# Docker entrypoint script for MTProto proxy

set -e

# Default values (container uses standard ports internally)
MTG_PORT=${MTG_PORT:-8443}
MTG_BIND_IP=${MTG_BIND_IP:-0.0.0.0}
MTG_WORKERS=${MTG_WORKERS:-2}
MTG_BUFFER_SIZE=${MTG_BUFFER_SIZE:-16384}
MTG_TIMEOUT=${MTG_TIMEOUT:-10}
MTG_STATS_IP=${MTG_STATS_IP:-0.0.0.0}
MTG_STATS_PORT=${MTG_STATS_PORT:-3001}
MTG_LOG_LEVEL=${MTG_LOG_LEVEL:-info}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate required environment variables
validate_env() {
    if [ -z "$MTG_SECRET" ]; then
        log_error "MTG_SECRET environment variable is required"
        exit 1
    fi

    # MTG v2 secrets can be either:
    # - 32 chars (16 bytes hex) for simple mode
    # - Longer for domain fronting (ee + 32 chars + domain hex)
    if [ ${#MTG_SECRET} -lt 32 ]; then
        log_error "MTG_SECRET must be at least 32 characters"
        exit 1
    fi

    # Check if it's a domain fronting secret (starts with 'ee')
    if [ "${MTG_SECRET#ee}" != "$MTG_SECRET" ]; then
        log_info "Using domain fronting secret (${#MTG_SECRET} characters)"
    else
        log_info "Using simple secret (${#MTG_SECRET} characters)"
        if [ ${#MTG_SECRET} -ne 32 ]; then
            log_error "Simple secrets must be exactly 32 characters (16 bytes in hex)"
            exit 1
        fi
    fi

    log_success "Environment validation passed"
}

# Generate proxy links
generate_links() {
    if [ -n "$SERVER_HOST" ]; then
        # Use external port from environment or default to internal port
        EXTERNAL_PORT=${EXTERNAL_MTG_PORT:-$MTG_PORT}

        PROXY_LINK="https://t.me/proxy?server=${SERVER_HOST}&port=${EXTERNAL_PORT}&secret=${MTG_SECRET}"
        PROXY_LINK_TG="tg://proxy?server=${SERVER_HOST}&port=${EXTERNAL_PORT}&secret=${MTG_SECRET}"

        log_success "Proxy links:"
        echo "Web: $PROXY_LINK"
        echo "Telegram: $PROXY_LINK_TG"
        echo ""
    fi
}

# Build mtg command using simple-run mode
build_command() {
    # mtg v2 uses simple-run mode: mtg simple-run <bind-to> <secret> [flags]
    # Use internal container port (MTG_PORT), not external port
    MTG_CMD="mtg simple-run ${MTG_BIND_IP}:${MTG_PORT} $MTG_SECRET"

    # Add concurrency (workers equivalent)
    if [ -n "$MTG_WORKERS" ]; then
        MTG_CMD="$MTG_CMD --concurrency $((MTG_WORKERS * 1024))"
    fi

    # Add buffer size
    if [ -n "$MTG_BUFFER_SIZE" ]; then
        MTG_CMD="$MTG_CMD --tcp-buffer ${MTG_BUFFER_SIZE}B"
    fi

    # Add timeout
    if [ -n "$MTG_TIMEOUT" ]; then
        MTG_CMD="$MTG_CMD --timeout ${MTG_TIMEOUT}s"
    fi

    # Add anti-replay cache size
    if [ -n "$MTG_ANTI_REPLAY_MAX_SIZE" ]; then
        MTG_CMD="$MTG_CMD --antireplay-cache-size ${MTG_ANTI_REPLAY_MAX_SIZE}KB"
    fi

    # Add domain fronting port (if domain is set)
    if [ -n "$MTG_DOMAIN" ]; then
        MTG_CMD="$MTG_CMD --domain-fronting-port 443"
    fi

    # Logging level (debug mode)
    case "$MTG_LOG_LEVEL" in
        "debug") MTG_CMD="$MTG_CMD --debug" ;;
    esac

    echo "$MTG_CMD"
}

# Signal handlers
handle_signal() {
    log_info "Received signal, shutting down gracefully..."
    if [ -n "$MTG_PID" ]; then
        kill -TERM "$MTG_PID" 2>/dev/null || true
        wait "$MTG_PID" 2>/dev/null || true
    fi
    exit 0
}

# Set up signal handlers
trap 'handle_signal' TERM INT

# Main execution
main() {
    log_info "Starting MTProto proxy container..."
    
    # Validate environment
    validate_env
    
    # Generate and display proxy links
    generate_links
    
    # Build command
    CMD=$(build_command)
    log_info "Command: $CMD"
    
    # Create log directory
    mkdir -p /app/logs
    
    # Start the proxy
    log_info "Starting proxy server..."
    exec $CMD
}

# Run main function if script is executed directly
if [ "$1" = "mtg" ] || [ -z "$1" ]; then
    main
else
    # Allow running other commands
    exec "$@"
fi
