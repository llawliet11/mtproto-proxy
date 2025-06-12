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

# Generate MTG v2 compatible secret with domain fronting
generate_secret() {
    local domain=${1:-"google.com"}

    echo "Generating MTG secret for domain: $domain" >&2

    # Generate 16 random bytes
    if command -v openssl &> /dev/null; then
        RANDOM_BYTES=$(openssl rand 16 | xxd -p -c 16)
    else
        # Fallback method
        RANDOM_BYTES=$(head -c 16 /dev/urandom | xxd -p -c 16)
    fi

    # Convert domain to hex
    DOMAIN_HEX=$(echo -n "$domain" | xxd -p -c 256)

    # MTG secret format for domain fronting: ee + 16 random bytes + domain in hex
    SECRET="ee${RANDOM_BYTES}${DOMAIN_HEX}"

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
    local domain=${2:-"google.com"}

    log_info "Generating new MTProto proxy secret for domain: $domain"

    SECRET=$(generate_secret "$domain")

    # MTG v2 secrets are longer (ee + 32 hex chars + domain hex)
    if [[ ! $SECRET == ee* ]]; then
        echo "Error: Generated secret doesn't start with 'ee'"
        exit 1
    fi

    log_success "Generated secret: $SECRET"
    log_info "Domain: $domain"
    log_info "Secret length: ${#SECRET} characters"

    if [[ "$1" == "--update-env" ]]; then
        update_env "$SECRET"
    else
        echo ""
        echo "To update your .env file, run:"
        echo "$0 --update-env $domain"
        echo ""
        echo "Or manually update MTG_SECRET in your .env file:"
        echo "MTG_SECRET=$SECRET"
    fi
}

main "$@"
