#!/bin/sh

# Docker entrypoint script for MTProto proxy

set -e

# Default values
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
    
    if [ ${#MTG_SECRET} -ne 32 ]; then
        log_error "MTG_SECRET must be exactly 32 characters (16 bytes in hex)"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Generate proxy links
generate_links() {
    if [ -n "$SERVER_HOST" ]; then
        PROXY_LINK="https://t.me/proxy?server=${SERVER_HOST}&port=${MTG_PORT}&secret=${MTG_SECRET}"
        PROXY_LINK_TG="tg://proxy?server=${SERVER_HOST}&port=${MTG_PORT}&secret=${MTG_SECRET}"
        
        log_success "Proxy links:"
        echo "Web: $PROXY_LINK"
        echo "Telegram: $PROXY_LINK_TG"
        echo ""
    fi
}

# Build mtg command
build_command() {
    MTG_CMD="mtg --bind ${MTG_BIND_IP}:${MTG_PORT} --secret $MTG_SECRET"
    
    # Add workers
    MTG_CMD="$MTG_CMD --workers $MTG_WORKERS"
    
    # Add buffer size
    MTG_CMD="$MTG_CMD --buffer-size $MTG_BUFFER_SIZE"
    
    # Add timeout
    MTG_CMD="$MTG_CMD --timeout ${MTG_TIMEOUT}s"
    
    # Security options
    if [ "$MTG_SECURE_ONLY" = "true" ]; then
        MTG_CMD="$MTG_CMD --secure-only"
    fi
    
    if [ "$MTG_DISABLE_IPV6" = "true" ]; then
        MTG_CMD="$MTG_CMD --disable-ipv6"
    fi
    
    # TLS domain
    if [ -n "$MTG_DOMAIN" ]; then
        MTG_CMD="$MTG_CMD --domain $MTG_DOMAIN"
    fi
    
    # Statistics
    if [ "$MTG_STATS_ENABLED" = "true" ]; then
        MTG_CMD="$MTG_CMD --stats ${MTG_STATS_IP}:${MTG_STATS_PORT}"
    fi
    
    # Anti-replay
    if [ -n "$MTG_ANTI_REPLAY_MAX_SIZE" ]; then
        MTG_CMD="$MTG_CMD --anti-replay-max-size $MTG_ANTI_REPLAY_MAX_SIZE"
    fi
    
    # Logging level
    case "$MTG_LOG_LEVEL" in
        "debug") MTG_CMD="$MTG_CMD -vv" ;;
        "info") MTG_CMD="$MTG_CMD -v" ;;
    esac
    
    # Upstream proxy
    if [ -n "$MTG_UPSTREAM_PROXY" ]; then
        MTG_CMD="$MTG_CMD --upstream-proxy $MTG_UPSTREAM_PROXY"
    fi
    
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
