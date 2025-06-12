#!/bin/bash

# Monitoring script for MTProto proxy

set -e

# Load environment variables
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
fi

# Default values
MTG_STATS_PORT=${MTG_STATS_PORT:-3001}
MTG_STATS_IP=${MTG_STATS_IP:-127.0.0.1}

# Colors
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

# Check if proxy is running
check_status() {
    if [[ -f logs/mtg.pid ]]; then
        PID=$(cat logs/mtg.pid)
        if kill -0 $PID 2>/dev/null; then
            log_success "Proxy is running (PID: $PID)"
            return 0
        else
            log_error "Proxy is not running (stale PID file)"
            rm logs/mtg.pid
            return 1
        fi
    else
        log_error "Proxy is not running"
        return 1
    fi
}

# Get statistics
get_stats() {
    if [[ "$MTG_STATS_ENABLED" != "true" ]]; then
        log_warning "Statistics are disabled"
        return 1
    fi
    
    local stats_url="http://${MTG_STATS_IP}:${MTG_STATS_PORT}/stats"
    
    if command -v curl &> /dev/null; then
        if curl -f -s "$stats_url" > /dev/null 2>&1; then
            log_info "Statistics from $stats_url:"
            curl -s "$stats_url" | jq . 2>/dev/null || curl -s "$stats_url"
            return 0
        else
            log_error "Cannot access statistics endpoint"
            return 1
        fi
    else
        log_warning "curl not available, cannot fetch statistics"
        return 1
    fi
}

# Show system resources
show_resources() {
    log_info "System resources:"
    
    # CPU usage
    if command -v top &> /dev/null; then
        echo "CPU usage:"
        top -bn1 | grep "Cpu(s)" || echo "CPU info not available"
    fi
    
    # Memory usage
    if command -v free &> /dev/null; then
        echo "Memory usage:"
        free -h
    elif [[ -f /proc/meminfo ]]; then
        echo "Memory usage:"
        grep -E "MemTotal|MemFree|MemAvailable" /proc/meminfo
    fi
    
    # Disk usage
    if command -v df &> /dev/null; then
        echo "Disk usage:"
        df -h . | tail -1
    fi
    
    # Network connections
    if command -v netstat &> /dev/null; then
        echo "Network connections on port ${MTG_PORT}:"
        netstat -an | grep ":${MTG_PORT}" | wc -l | xargs echo "Active connections:"
    elif command -v ss &> /dev/null; then
        echo "Network connections on port ${MTG_PORT}:"
        ss -an | grep ":${MTG_PORT}" | wc -l | xargs echo "Active connections:"
    fi
}

# Show recent logs
show_logs() {
    local lines=${1:-20}
    
    if [[ -f logs/mtg.log ]]; then
        log_info "Recent logs (last $lines lines):"
        tail -n "$lines" logs/mtg.log
    else
        log_warning "Log file not found"
    fi
}

# Continuous monitoring
monitor_continuous() {
    local interval=${1:-30}
    
    log_info "Starting continuous monitoring (interval: ${interval}s, press Ctrl+C to stop)"
    
    while true; do
        clear
        echo "=== MTProto Proxy Monitor - $(date) ==="
        echo ""
        
        check_status
        echo ""
        
        get_stats
        echo ""
        
        show_resources
        echo ""
        
        echo "Next update in ${interval} seconds..."
        sleep "$interval"
    done
}

# Main function
main() {
    case "${1:-status}" in
        "status")
            check_status
            ;;
        "stats")
            get_stats
            ;;
        "resources")
            show_resources
            ;;
        "logs")
            show_logs "${2:-20}"
            ;;
        "monitor")
            monitor_continuous "${2:-30}"
            ;;
        "all")
            check_status
            echo ""
            get_stats
            echo ""
            show_resources
            echo ""
            show_logs 10
            ;;
        *)
            echo "Usage: $0 {status|stats|resources|logs|monitor|all} [options]"
            echo ""
            echo "Commands:"
            echo "  status     - Check if proxy is running"
            echo "  stats      - Show proxy statistics"
            echo "  resources  - Show system resources"
            echo "  logs [N]   - Show last N log lines (default: 20)"
            echo "  monitor [S] - Continuous monitoring every S seconds (default: 30)"
            echo "  all        - Show all information"
            exit 1
            ;;
    esac
}

main "$@"
