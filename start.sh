#!/bin/bash

# MTProto Proxy Startup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Load environment variables
load_env() {
    if [[ -f .env ]]; then
        log_info "Loading environment variables from .env"
        export $(grep -v '^#' .env | xargs)
    else
        log_error ".env file not found. Please copy .env.example to .env and configure it."
        exit 1
    fi
}

# Validate configuration
validate_config() {
    log_info "Validating configuration..."
    
    if [[ -z "$MTG_SECRET" ]]; then
        log_error "MTG_SECRET is not set. Please configure it in .env file."
        exit 1
    fi
    
    if [[ ${#MTG_SECRET} -ne 32 ]]; then
        log_error "MTG_SECRET must be exactly 32 characters (16 bytes in hex)."
        exit 1
    fi
    
    if [[ -z "$MTG_PORT" ]]; then
        MTG_PORT=8443
        log_warning "MTG_PORT not set, using default: $MTG_PORT"
    fi
    
    if [[ -z "$SERVER_HOST" ]]; then
        SERVER_HOST="localhost"
        log_warning "SERVER_HOST not set, using default: $SERVER_HOST"
    fi
    
    log_success "Configuration validated"
}

# Check if mtg is installed
check_mtg() {
    if ! command -v mtg &> /dev/null; then
        log_error "mtg is not installed. Please run ./install.sh first."
        exit 1
    fi
    
    log_info "mtg found: $(which mtg)"
}

# Create necessary directories
create_dirs() {
    mkdir -p logs config
}

# Generate proxy link
generate_proxy_link() {
    local secret_hex="$MTG_SECRET"
    local secret_base64=$(echo -n "$secret_hex" | xxd -r -p | base64 | tr -d '=')
    
    PROXY_LINK="https://t.me/proxy?server=${SERVER_HOST}&port=${MTG_PORT}&secret=${secret_hex}"
    PROXY_LINK_TG="tg://proxy?server=${SERVER_HOST}&port=${MTG_PORT}&secret=${secret_hex}"
    
    log_success "Proxy links generated:"
    echo "Web link: $PROXY_LINK"
    echo "Telegram link: $PROXY_LINK_TG"
    echo ""
    echo "QR Code for easy sharing:"
    if command -v qrencode &> /dev/null; then
        qrencode -t ANSIUTF8 "$PROXY_LINK"
    else
        echo "Install qrencode to display QR code: sudo apt-get install qrencode"
    fi
}

# Start the proxy
start_proxy() {
    log_info "Starting MTProto proxy..."
    
    # Build mtg command
    MTG_CMD="mtg"
    
    # Add basic parameters
    MTG_CMD="$MTG_CMD --bind ${MTG_BIND_IP:-0.0.0.0}:${MTG_PORT}"
    MTG_CMD="$MTG_CMD --secret $MTG_SECRET"
    
    # Add optional parameters
    if [[ -n "$MTG_WORKERS" ]]; then
        MTG_CMD="$MTG_CMD --workers $MTG_WORKERS"
    fi
    
    if [[ -n "$MTG_BUFFER_SIZE" ]]; then
        MTG_CMD="$MTG_CMD --buffer-size $MTG_BUFFER_SIZE"
    fi
    
    if [[ "$MTG_SECURE_ONLY" == "true" ]]; then
        MTG_CMD="$MTG_CMD --secure-only"
    fi
    
    if [[ "$MTG_DISABLE_IPV6" == "true" ]]; then
        MTG_CMD="$MTG_CMD --disable-ipv6"
    fi
    
    if [[ -n "$MTG_DOMAIN" ]]; then
        MTG_CMD="$MTG_CMD --domain $MTG_DOMAIN"
    fi
    
    if [[ "$MTG_STATS_ENABLED" == "true" && -n "$MTG_STATS_IP" && -n "$MTG_STATS_PORT" ]]; then
        MTG_CMD="$MTG_CMD --stats ${MTG_STATS_IP}:${MTG_STATS_PORT}"
    fi
    
    if [[ -n "$MTG_ANTI_REPLAY_MAX_SIZE" ]]; then
        MTG_CMD="$MTG_CMD --anti-replay-max-size $MTG_ANTI_REPLAY_MAX_SIZE"
    fi
    
    if [[ -n "$MTG_TIMEOUT" ]]; then
        MTG_CMD="$MTG_CMD --timeout ${MTG_TIMEOUT}s"
    fi
    
    # Logging
    case "${MTG_LOG_LEVEL:-info}" in
        "debug") MTG_CMD="$MTG_CMD -vv" ;;
        "info") MTG_CMD="$MTG_CMD -v" ;;
        "warn"|"error") ;;
    esac
    
    log_info "Command: $MTG_CMD"
    
    # Start the proxy
    if [[ "$1" == "--daemon" ]]; then
        log_info "Starting in daemon mode..."
        nohup $MTG_CMD > logs/mtg.log 2>&1 &
        echo $! > logs/mtg.pid
        log_success "Proxy started in background (PID: $(cat logs/mtg.pid))"
    else
        log_info "Starting in foreground mode..."
        $MTG_CMD 2>&1 | tee logs/mtg.log
    fi
}

# Stop the proxy
stop_proxy() {
    if [[ -f logs/mtg.pid ]]; then
        PID=$(cat logs/mtg.pid)
        if kill -0 $PID 2>/dev/null; then
            log_info "Stopping proxy (PID: $PID)..."
            kill $PID
            rm logs/mtg.pid
            log_success "Proxy stopped"
        else
            log_warning "Proxy process not found"
            rm logs/mtg.pid
        fi
    else
        log_warning "PID file not found"
    fi
}

# Show status
show_status() {
    if [[ -f logs/mtg.pid ]]; then
        PID=$(cat logs/mtg.pid)
        if kill -0 $PID 2>/dev/null; then
            log_success "Proxy is running (PID: $PID)"
            
            # Show statistics if available
            if [[ "$MTG_STATS_ENABLED" == "true" ]]; then
                log_info "Statistics available at: http://${MTG_STATS_IP:-127.0.0.1}:${MTG_STATS_PORT:-3001}/stats"
            fi
            
            generate_proxy_link
        else
            log_error "Proxy is not running (stale PID file)"
            rm logs/mtg.pid
        fi
    else
        log_error "Proxy is not running"
    fi
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            load_env
            validate_config
            check_mtg
            create_dirs
            generate_proxy_link
            start_proxy
            ;;
        "daemon")
            load_env
            validate_config
            check_mtg
            create_dirs
            generate_proxy_link
            start_proxy --daemon
            ;;
        "stop")
            stop_proxy
            ;;
        "restart")
            stop_proxy
            sleep 2
            load_env
            validate_config
            check_mtg
            create_dirs
            start_proxy --daemon
            ;;
        "status")
            load_env
            show_status
            ;;
        "link")
            load_env
            validate_config
            generate_proxy_link
            ;;
        *)
            echo "Usage: $0 {start|daemon|stop|restart|status|link}"
            echo ""
            echo "Commands:"
            echo "  start   - Start proxy in foreground"
            echo "  daemon  - Start proxy in background"
            echo "  stop    - Stop proxy"
            echo "  restart - Restart proxy"
            echo "  status  - Show proxy status"
            echo "  link    - Show proxy links"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
