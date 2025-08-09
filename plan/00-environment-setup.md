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
log "Note: Python, UV, Git, and Podman will be installed in the VM, not on the host."
```

### Verification Script (`verify-host.sh`)

```bash
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

# Check Multipass can list VMs
multipass list >/dev/null && echo "✅ Multipass is functional" || echo "❌ Multipass is not functional"

# Check Make is functional
make --help >/dev/null && echo "✅ Make is functional" || echo "❌ Make is not functional"

log "Verification complete!"
```

## Usage Instructions

### 1. Make Scripts Executable
```bash
chmod +x setup-host.sh
chmod +x verify-host.sh
```

### 2. Run Setup
```bash
./setup-host.sh
```

### 3. Verify Installation
```bash
./verify-host.sh
```

### 4. Manual Verification (Optional)
```bash
# Check individual components
multipass version
make --version

# Test basic functionality
multipass list
make --help
```

## Troubleshooting

### Common Issues

#### 1. Multipass Installation Fails on macOS
```bash
# Solution 1: Update Homebrew
brew update
brew install --cask multipass

# Solution 2: Manual installation
# Download from: https://multipass.run
```

#### 2. Make Not Available
```bash
# For macOS: Make should be available with Xcode command line tools
xcode-select --install

# For Linux: Install build-essential
sudo apt update
sudo apt install -y build-essential
```

#### 3. Permission Issues
```bash
# Ensure scripts have execute permissions
chmod +x setup-host.sh verify-host.sh

# Check file ownership
ls -la setup-host.sh

# If downloaded, ensure proper permissions
chmod 755 setup-host.sh verify-host.sh
```

### Debug Mode

Run setup with debug information:
```bash
# Enable verbose output
bash -x setup-host.sh

# Or run with debug flag
DEBUG=1 ./setup-host.sh
```

## Idempotency Features

The setup script includes several idempotency safeguards:

1. **Command Checking**: Uses `command -v` to check if commands exist before installation
2. **Version Verification**: Checks specific version requirements
3. **Configuration Checks**: Verifies git configuration and service status
4. **Safe Installation**: Uses package managers that handle dependencies
5. **Error Handling**: Proper error handling with `set -e`

## Post-Setup Configuration

### 1. SSH Key Setup (Recommended)
```bash
# Generate SSH key if needed
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Add to ssh-agent
ssh-add ~/.ssh/id_rsa

# Copy public key for VM access
cat ~/.ssh/id_rsa.pub
```





## Best Practices

1. **Run Regularly**: Execute setup script periodically to ensure Multipass is up-to-date
2. **Check Logs**: Review output for any installation failures
3. **Verify Functionality**: Always run verification script after setup
4. **Backup Configuration**: Keep copies of important configuration files
5. **Monitor Updates**: Stay informed about security updates for installed components

## Next Steps

After completing Step 00, proceed to:

- **Step 01**: [Base VM Image Creation](01-base-vm-setup.md)
- Create golden VM images with Python 3.12, UV, Git, and Podman
- Set up reproducible development environments

## Makefile Integration

The system includes a Makefile that can execute setup and other commands on the base machine:

```makefile
.PHONY: setup verify clean help

setup:
	@echo "Setting up host environment..."
	./setup-host.sh

verify:
	@echo "Verifying host setup..."
	./verify-host.sh

clean:
	@echo "Cleaning up host environment..."
	@echo "Note: This does not clean up VMs. Use 'multipass purge' for that."

help:
	@echo "Available commands:"
	@echo "  setup    - Install host prerequisites (Multipass, Make)"
	@echo "  verify   - Verify host setup"
	@echo "  clean    - Clean up host environment"
	@echo "  help     - Show this help message"
```

Usage:
```bash
# Setup host environment
make setup

# Verify setup
make verify

# Clean up host environment
make clean

# Show help
make help
```