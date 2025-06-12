#!/bin/bash

# Complete setup script for MTProto Proxy
# This script handles the entire setup process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

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

log_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# Welcome message
show_welcome() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
 __  __ _____ ____            _          ____
|  \/  |_   _|  _ \ _ __ ___ | |_ ___   |  _ \ _ __ _____  ___   _
| |\/| | | | | |_) | '__/ _ \| __/ _ \  | |_) | '__/ _ \ \/ / | | |
| |  | | | | |  __/| | | (_) | || (_) | |  __/| | | (_) >  <| |_| |
|_|  |_| |_| |_|   |_|  \___/ \__\___/  |_|   |_|  \___/_/\_\\__, |
                                                             |___/
EOF
    echo -e "${NC}"
    echo "Welcome to MTProto Proxy Setup!"
    echo "This script will help you set up a secure Telegram proxy server."
    echo ""
}

# Check system requirements
check_requirements() {
    log_header "Checking System Requirements"

    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_success "Operating System: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_success "Operating System: macOS"
    else
        log_warning "Operating System: $OSTYPE (may not be fully supported)"
    fi

    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. This is not recommended for security."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check available tools
    local tools=("curl" "wget" "git")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is available"
        else
            log_warning "$tool is not installed"
        fi
    done
}

# Interactive configuration
interactive_config() {
    log_header "Interactive Configuration"

    echo "Let's configure your MTProto proxy..."
    echo ""

    # Server host
    read -p "Enter your server's public IP or domain name [localhost]: " SERVER_HOST
    SERVER_HOST=${SERVER_HOST:-localhost}

    # Port
    read -p "Enter the port to listen on [8443]: " MTG_PORT
    MTG_PORT=${MTG_PORT:-8443}

    # Workers
    read -p "Enter number of worker processes [2]: " MTG_WORKERS
    MTG_WORKERS=${MTG_WORKERS:-2}

    # TLS domain for camouflage
    read -p "Enter domain for TLS camouflage (optional, helps bypass DPI): " MTG_DOMAIN

    # Statistics
    read -p "Enable statistics endpoint? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        MTG_STATS_ENABLED="true"
        read -p "Statistics port [3001]: " MTG_STATS_PORT
        MTG_STATS_PORT=${MTG_STATS_PORT:-3001}
    else
        MTG_STATS_ENABLED="false"
        MTG_STATS_PORT="3001"
    fi

    # Generate secret
    log_info "Generating proxy secret..."
    if command -v openssl &> /dev/null; then
        MTG_SECRET=$(openssl rand -hex 16)
    else
        MTG_SECRET=$(head /dev/urandom | tr -dc a-f0-9 | head -c 32)
    fi

    log_success "Configuration completed!"
}

# Update .env file with user configuration
update_env_file() {
    log_header "Updating Configuration File"

    # Backup existing .env if it exists
    if [[ -f .env ]]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        log_info "Backed up existing .env file"
    fi

    # Create .env from template
    cp .env.example .env

    # Update values
    sed -i.tmp "s/MTG_SECRET=.*/MTG_SECRET=$MTG_SECRET/" .env
    sed -i.tmp "s/SERVER_HOST=.*/SERVER_HOST=$SERVER_HOST/" .env
    sed -i.tmp "s/MTG_PORT=.*/MTG_PORT=$MTG_PORT/" .env
    sed -i.tmp "s/MTG_WORKERS=.*/MTG_WORKERS=$MTG_WORKERS/" .env
    sed -i.tmp "s/MTG_STATS_ENABLED=.*/MTG_STATS_ENABLED=$MTG_STATS_ENABLED/" .env
    sed -i.tmp "s/MTG_STATS_PORT=.*/MTG_STATS_PORT=$MTG_STATS_PORT/" .env

    if [[ -n "$MTG_DOMAIN" ]]; then
        sed -i.tmp "s/MTG_DOMAIN=.*/MTG_DOMAIN=$MTG_DOMAIN/" .env
    fi

    # Clean up temporary file
    rm .env.tmp

    log_success "Configuration file updated"
}

# Choose installation method
choose_installation() {
    log_header "Choose Installation Method"

    echo "Please choose your preferred installation method:"
    echo "1) Docker (Recommended - Easy and isolated)"
    echo "2) Manual installation (Direct on system)"
    echo ""

    while true; do
        read -p "Enter your choice (1 or 2): " choice
        case $choice in
            1)
                INSTALL_METHOD="docker"
                break
                ;;
            2)
                INSTALL_METHOD="manual"
                break
                ;;
            *)
                echo "Please enter 1 or 2"
                ;;
        esac
    done

    log_info "Selected installation method: $INSTALL_METHOD"
}

# Docker installation
install_docker() {
    log_header "Docker Installation"

    # Check if Docker is installed
    if command -v docker &> /dev/null; then
        log_success "Docker is already installed"
    else
        log_info "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        log_success "Docker installed"
    fi

    # Check if Docker Compose is installed
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose is already installed"
    else
        log_info "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose installed"
    fi

    # Start Docker service
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo systemctl start docker
        sudo systemctl enable docker
        log_success "Docker service started and enabled"
    fi
}

# Manual installation
install_manual() {
    log_header "Manual Installation"

    log_info "Running manual installation script..."
    ./install.sh

    log_success "Manual installation completed"
}

# Generate proxy links
generate_links() {
    log_header "Proxy Links"

    local web_link="https://t.me/proxy?server=${SERVER_HOST}&port=${MTG_PORT}&secret=${MTG_SECRET}"
    local tg_link="tg://proxy?server=${SERVER_HOST}&port=${MTG_PORT}&secret=${MTG_SECRET}"

    echo "Your proxy links:"
    echo ""
    echo -e "${GREEN}Web link:${NC}"
    echo "$web_link"
    echo ""
    echo -e "${GREEN}Telegram link:${NC}"
    echo "$tg_link"
    echo ""

    # Save links to file
    cat > proxy-links.txt << EOF
MTProto Proxy Links
Generated on: $(date)

Web link: $web_link
Telegram link: $tg_link

Configuration:
- Server: $SERVER_HOST
- Port: $MTG_PORT
- Secret: $MTG_SECRET
EOF

    log_success "Proxy links saved to proxy-links.txt"
}

# Show next steps
show_next_steps() {
    log_header "Next Steps"

    echo "Setup completed successfully! Here's what to do next:"
    echo ""

    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        echo "1. Start the proxy:"
        echo "   docker-compose up -d"
        echo ""
        echo "2. Check logs:"
        echo "   docker-compose logs -f"
        echo ""
        echo "3. Stop the proxy:"
        echo "   docker-compose down"
    else
        echo "1. Start the proxy:"
        echo "   ./start.sh daemon"
        echo ""
        echo "2. Check status:"
        echo "   ./start.sh status"
        echo ""
        echo "3. Monitor the proxy:"
        echo "   ./scripts/monitor.sh"
        echo ""
        echo "4. Stop the proxy:"
        echo "   ./start.sh stop"
    fi

    echo ""
    echo "Additional commands:"
    echo "- Generate new secret: ./scripts/generate-secret.sh --update-env"
    echo "- Monitor resources: ./scripts/monitor.sh resources"
    echo "- View logs: ./scripts/monitor.sh logs"
    echo ""
    echo "Your proxy links are saved in proxy-links.txt"
    echo ""
    echo -e "${GREEN}Enjoy your MTProto proxy!${NC}"
}

# Main setup function
main() {
    show_welcome
    check_requirements
    interactive_config
    update_env_file
    choose_installation

    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        install_docker
    else
        install_manual
    fi

    generate_links
    show_next_steps

    log_success "Setup completed successfully!"
}

# Run main function
main "$@"