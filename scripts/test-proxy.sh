#!/bin/bash

# Test script for MTProto proxy

set -e

# Load environment variables
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
fi

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

# Test configuration
test_config() {
    log_info "Testing configuration..."
    
    if [[ -z "$MTG_SECRET" ]]; then
        log_error "MTG_SECRET is not set"
        return 1
    fi
    
    if [[ ${#MTG_SECRET} -ne 32 ]]; then
        log_error "MTG_SECRET must be 32 characters"
        return 1
    fi
    
    if [[ -z "$MTG_PORT" ]]; then
        log_error "MTG_PORT is not set"
        return 1
    fi
    
    log_success "Configuration is valid"
    return 0
}

# Test port availability
test_port() {
    log_info "Testing port availability..."
    
    if nc -z localhost "$MTG_PORT" 2>/dev/null; then
        log_success "Port $MTG_PORT is accessible"
        return 0
    else
        log_error "Port $MTG_PORT is not accessible"
        return 1
    fi
}

# Test statistics endpoint
test_stats() {
    if [[ "$MTG_STATS_ENABLED" != "true" ]]; then
        log_info "Statistics endpoint is disabled"
        return 0
    fi
    
    log_info "Testing statistics endpoint..."
    
    local stats_url="http://localhost:${MTG_STATS_PORT}/stats"
    
    if curl -f -s "$stats_url" > /dev/null 2>&1; then
        log_success "Statistics endpoint is accessible"
        return 0
    else
        log_warning "Statistics endpoint is not accessible"
        return 1
    fi
}

# Test proxy functionality
test_proxy_connection() {
    log_info "Testing proxy connection..."
    
    # Simple connection test
    if timeout 5 bash -c "</dev/tcp/localhost/$MTG_PORT" 2>/dev/null; then
        log_success "Proxy accepts connections"
        return 0
    else
        log_error "Proxy does not accept connections"
        return 1
    fi
}

# Test Docker setup
test_docker() {
    if [[ ! -f docker-compose.yml ]]; then
        log_info "Docker setup not found, skipping Docker tests"
        return 0
    fi
    
    log_info "Testing Docker setup..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker is installed"
    else
        log_error "Docker is not installed"
        return 1
    fi
    
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose is installed"
    else
        log_error "Docker Compose is not installed"
        return 1
    fi
    
    # Test if containers are running
    if docker-compose ps | grep -q "Up"; then
        log_success "Docker containers are running"
    else
        log_warning "Docker containers are not running"
    fi
    
    return 0
}

# Test system resources
test_resources() {
    log_info "Testing system resources..."
    
    # Check available memory
    if command -v free &> /dev/null; then
        local mem_available=$(free -m | awk 'NR==2{printf "%.0f", $7}')
        if [[ $mem_available -gt 100 ]]; then
            log_success "Sufficient memory available: ${mem_available}MB"
        else
            log_warning "Low memory available: ${mem_available}MB"
        fi
    fi
    
    # Check disk space
    if command -v df &> /dev/null; then
        local disk_available=$(df . | awk 'NR==2{print $4}')
        if [[ $disk_available -gt 1000000 ]]; then  # 1GB in KB
            log_success "Sufficient disk space available"
        else
            log_warning "Low disk space available"
        fi
    fi
    
    return 0
}

# Generate test report
generate_report() {
    local timestamp=$(date)
    local report_file="test-report-$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
MTProto Proxy Test Report
Generated: $timestamp

Configuration:
- Secret: ${MTG_SECRET:0:8}...
- Port: $MTG_PORT
- Server: $SERVER_HOST
- Workers: $MTG_WORKERS
- Stats Enabled: $MTG_STATS_ENABLED

Test Results:
EOF
    
    echo "Report saved to: $report_file"
}

# Main test function
main() {
    log_info "Starting MTProto proxy tests..."
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Run tests
    tests=(
        "test_config"
        "test_port"
        "test_stats"
        "test_proxy_connection"
        "test_docker"
        "test_resources"
    )
    
    for test in "${tests[@]}"; do
        ((tests_total++))
        if $test; then
            ((tests_passed++))
        fi
        echo ""
    done
    
    # Summary
    echo "=========================="
    echo "Test Summary:"
    echo "Passed: $tests_passed/$tests_total"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        log_success "All tests passed! Your proxy is ready to use."
        
        # Show proxy links
        if [[ -n "$SERVER_HOST" && "$SERVER_HOST" != "localhost" ]]; then
            echo ""
            echo "Your proxy links:"
            echo "https://t.me/proxy?server=${SERVER_HOST}&port=${MTG_PORT}&secret=${MTG_SECRET}"
        fi
    else
        log_warning "Some tests failed. Please check the issues above."
    fi
    
    # Generate report
    generate_report
}

main "$@"
