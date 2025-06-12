#!/bin/sh

# Health check script for MTProto proxy

# Default values
MTG_STATS_PORT=${MTG_STATS_PORT:-3001}
MTG_PORT=${MTG_PORT:-8443}

# Check if statistics endpoint is enabled and accessible
check_stats() {
    if [ "$MTG_STATS_ENABLED" = "true" ]; then
        if curl -f -s "http://localhost:${MTG_STATS_PORT}/health" > /dev/null 2>&1; then
            return 0
        elif curl -f -s "http://localhost:${MTG_STATS_PORT}/" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Check if main proxy port is listening
check_port() {
    if nc -z localhost "$MTG_PORT" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Check if mtg process is running
check_process() {
    if pgrep -f "mtg" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Main health check
main() {
    # Check if process is running
    if ! check_process; then
        echo "UNHEALTHY: mtg process not found"
        exit 1
    fi
    
    # Check if port is listening
    if ! check_port; then
        echo "UNHEALTHY: proxy port $MTG_PORT not listening"
        exit 1
    fi
    
    # Check statistics endpoint if enabled
    if [ "$MTG_STATS_ENABLED" = "true" ]; then
        if ! check_stats; then
            echo "WARNING: statistics endpoint not accessible"
            # Don't fail health check for stats endpoint
        fi
    fi
    
    echo "HEALTHY: proxy is running on port $MTG_PORT"
    exit 0
}

main "$@"
