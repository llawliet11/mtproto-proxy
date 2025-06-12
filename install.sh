#!/bin/bash

# MTProto Proxy Installation Script
# This script installs and configures the mtg MTProto proxy

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. This is not recommended for security reasons."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get &> /dev/null; then
            DISTRO="debian"
        elif command -v yum &> /dev/null; then
            DISTRO="rhel"
        elif command -v pacman &> /dev/null; then
            DISTRO="arch"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    else
        OS="unknown"
        DISTRO="unknown"
    fi
    
    log_info "Detected OS: $OS ($DISTRO)"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    case $DISTRO in
        "debian")
            sudo apt-get update
            sudo apt-get install -y curl wget git build-essential
            ;;
        "rhel")
            sudo yum update -y
            sudo yum install -y curl wget git gcc
            ;;
        "arch")
            sudo pacman -Sy --noconfirm curl wget git base-devel
            ;;
        "macos")
            if ! command -v brew &> /dev/null; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install curl wget git
            ;;
        *)
            log_warning "Unknown distribution. Please install curl, wget, and git manually."
            ;;
    esac
}

# Install Go
install_go() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        log_info "Go is already installed (version $GO_VERSION)"
        return
    fi
    
    log_info "Installing Go..."
    
    GO_VERSION="1.21.5"
    case $OS in
        "linux")
            GO_ARCH="linux-amd64"
            ;;
        "macos")
            GO_ARCH="darwin-amd64"
            ;;
        *)
            log_error "Unsupported OS for Go installation"
            exit 1
            ;;
    esac
    
    cd /tmp
    wget "https://golang.org/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz"
    
    if [[ $OS == "linux" ]]; then
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.${GO_ARCH}.tar.gz"
        
        # Add Go to PATH
        if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        fi
        export PATH=$PATH:/usr/local/go/bin
    else
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.${GO_ARCH}.tar.gz"
        export PATH=$PATH:/usr/local/go/bin
    fi
    
    rm "go${GO_VERSION}.${GO_ARCH}.tar.gz"
    log_success "Go installed successfully"
}

# Install mtg
install_mtg() {
    log_info "Installing mtg MTProto proxy..."
    
    # Create installation directory
    mkdir -p ~/mtg-proxy
    cd ~/mtg-proxy
    
    # Clone and build mtg
    git clone https://github.com/9seconds/mtg.git
    cd mtg
    go build -o ../mtg ./cmd/mtg
    cd ..
    
    # Make binary executable
    chmod +x mtg
    
    # Create symlink for global access
    sudo ln -sf "$(pwd)/mtg" /usr/local/bin/mtg
    
    log_success "mtg installed successfully"
}

# Create directories
create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p logs config scripts
    
    log_success "Directories created"
}

# Generate secret if not exists
generate_secret() {
    if [[ -f .env ]] && grep -q "MTG_SECRET=" .env && [[ $(grep "MTG_SECRET=" .env | cut -d'=' -f2) != "" ]]; then
        log_info "Secret already exists in .env file"
        return
    fi
    
    log_info "Generating proxy secret..."
    
    if command -v openssl &> /dev/null; then
        SECRET=$(openssl rand -hex 16)
    else
        # Fallback method
        SECRET=$(head /dev/urandom | tr -dc a-f0-9 | head -c 32)
    fi
    
    # Update .env file
    if [[ -f .env ]]; then
        sed -i.bak "s/MTG_SECRET=.*/MTG_SECRET=$SECRET/" .env
    else
        cp .env.example .env
        sed -i.bak "s/MTG_SECRET=.*/MTG_SECRET=$SECRET/" .env
    fi
    
    log_success "Secret generated: $SECRET"
}

# Create systemd service
create_service() {
    if [[ $OS != "linux" ]]; then
        log_info "Skipping systemd service creation (not on Linux)"
        return
    fi
    
    log_info "Creating systemd service..."
    
    SERVICE_FILE="/etc/systemd/system/mtproto-proxy.service"
    
    sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=MTProto Proxy
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/start.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable mtproto-proxy
    
    log_success "Systemd service created"
}

# Main installation function
main() {
    log_info "Starting MTProto Proxy installation..."
    
    check_root
    detect_os
    install_dependencies
    install_go
    install_mtg
    create_directories
    generate_secret
    create_service
    
    log_success "Installation completed successfully!"
    log_info "Next steps:"
    echo "1. Edit .env file to configure your proxy"
    echo "2. Run './start.sh' to start the proxy"
    echo "3. Check logs with 'tail -f logs/mtg.log'"
    echo "4. Get your proxy link from the startup output"
}

# Run main function
main "$@"
