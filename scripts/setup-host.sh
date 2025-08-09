#!/bin/bash
# setup-host.sh - Idempotent host environment setup

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log "Installing $1..."
        return 1
    else
        log "$1 already installed"
        return 0
    fi
}

install_multipass() {
    if ! check_command multipass; then
        log "Installing Multipass..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install --cask multipass
        else
            # Linux installation
            curl -fsSL https://multipass.run | sh
        fi
        multipass version
    fi
}

install_make() {
    if ! check_command make; then
        log "Installing Make..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install make
        else
            # Ubuntu/Debian
            sudo apt update
            sudo apt install -y build-essential
        fi
    fi
}

# Main execution
log "Starting host environment setup..."

install_multipass
install_make

log "Host environment setup complete!"
log "Run './verify-host.sh' to verify all components are installed correctly."
