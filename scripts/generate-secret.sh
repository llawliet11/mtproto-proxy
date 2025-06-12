#!/bin/bash

# Script to generate a new MTProto proxy secret

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Generate secret
generate_secret() {
    if command -v openssl &> /dev/null; then
        SECRET=$(openssl rand -hex 16)
    elif command -v xxd &> /dev/null; then
        SECRET=$(head -c 16 /dev/urandom | xxd -p)
    else
        # Fallback method
        SECRET=$(head /dev/urandom | tr -dc a-f0-9 | head -c 32)
    fi
    
    echo "$SECRET"
}

# Update .env file
update_env() {
    local secret="$1"
    
    if [[ -f .env ]]; then
        # Backup existing .env
        cp .env .env.bak
        
        # Update secret
        sed -i.tmp "s/MTG_SECRET=.*/MTG_SECRET=$secret/" .env
        rm .env.tmp
        
        log_success "Updated .env file (backup saved as .env.bak)"
    else
        log_info ".env file not found, creating from template..."
        cp .env.example .env
        sed -i.tmp "s/MTG_SECRET=.*/MTG_SECRET=$secret/" .env
        rm .env.tmp
        log_success "Created .env file with new secret"
    fi
}

# Main function
main() {
    log_info "Generating new MTProto proxy secret..."
    
    SECRET=$(generate_secret)
    
    if [[ ${#SECRET} -ne 32 ]]; then
        echo "Error: Generated secret is not 32 characters long"
        exit 1
    fi
    
    log_success "Generated secret: $SECRET"
    
    if [[ "$1" == "--update-env" ]]; then
        update_env "$SECRET"
    else
        echo ""
        echo "To update your .env file, run:"
        echo "$0 --update-env"
        echo ""
        echo "Or manually update MTG_SECRET in your .env file:"
        echo "MTG_SECRET=$SECRET"
    fi
}

main "$@"
