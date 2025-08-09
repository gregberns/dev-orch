#!/bin/bash
# verify-host.sh - Verify all prerequisites are installed

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_version() {
    local cmd="$1"
    local expected_version="$2"
    local actual_version=$($cmd --version 2>/dev/null || echo "not installed")

    if [[ "$actual_version" == *"not installed"* ]]; then
        echo "❌ $cmd: NOT INSTALLED"
        return 1
    elif [[ -n "$expected_version" && "$actual_version" != *"$expected_version"* ]]; then
        echo "⚠️  $cmd: $actual_version (expected: $expected_version)"
        return 0
    else
        echo "✅ $cmd: $actual_version"
        return 0
    fi
}

log "Verifying host environment..."

# Check Multipass
check_version "multipass" ""

# Check Make
check_version "make" ""

# Additional verification
log "Performing additional verification..."

# Check Make is functional
make --help >/dev/null && echo "✅ Make is functional" || echo "❌ Make is not functional"

log "Verification complete!"
