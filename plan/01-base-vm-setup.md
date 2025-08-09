# Step 01: Base VM Image Setup

## Overview

This step creates a reproducible "golden image" VM that contains all the development prerequisites needed for consistent development environments. The golden image serves as a template that can be cloned infinitely using Multipass snapshots, ensuring every development environment starts with identical base configurations.

The template system allows you to choose from pre-built examples or create custom templates tailored to your specific development needs.

## Prerequisites

Before proceeding with Step 01, ensure you have completed Step 00:

- ✅ Multipass installed and configured
- ✅ Make installed and configured on host machine
- ✅ SSH keys set up for VM access
- ✅ gomplate installed on host machine (for template rendering)

**Note**: Python 3.12, UV, Git, and Podman will be installed in the VM, not on the host machine.

## Golden Image Configuration

### Cloud-Init Template (`cloud-init.j2`)

The cloud-init configuration is defined as a gomplate template that allows for variable substitution. This approach provides flexibility for different environments and configurations without requiring Python.

**Template System**:
- **template-examples/**: Starter templates for different development environments
- **templates/**: Active templates you're currently using
- **Flexible**: Copy, modify, and create custom templates as needed

**Template File**: `templates/cloud-init.j2` (default template)

**Key Template Variables**:
- `{{ env "GIT_NAME" }}` - Git user name
- `{{ env "GIT_EMAIL" }}` - Git user email
- `{{ env "SSH_PUBLIC_KEY" }}` - SSH public key for VM access

**Environment Configuration**: Create a `.env` file based on `.env.example`:

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your configuration
vim .env
```

**Sample .env Configuration**:
```bash
# Git configuration
GIT_NAME="Developer Name"
GIT_EMAIL="developer@example.com"

# SSH configuration
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."

# VM configuration
VM_NAME="golden-template"
VM_CPUS=2
VM_MEMORY=4G
VM_DISK=20G
```

**Rendering the Template**:
```bash
# Render the template using the Makefile
make render-template

# Or manually with gomplate
gomplate -f cloud-init.j2 -d .env=.env > cloud-init.yaml
```

**Rendered Configuration**: The result is `cloud-init.yaml` which can be used with Multipass.

## Base Image Creation Script

### `create-base-image.sh`

```bash
#!/bin/bash
# create-base-image.sh - Create golden VM image from rendered template

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Configuration
CLOUD_INIT_FILE="cloud-init.yaml"
SNAPSHOT_NAME="golden-image"

# Check prerequisites
log "Checking prerequisites..."
if ! command -v multipass &> /dev/null; then
    error_exit "Multipass is not installed. Please run Step 00 first."
fi

if ! command -v make &> /dev/null; then
    error_exit "Make is not installed. Please run Step 00 first."
fi

if ! command -v python3 &> /dev/null; then
    error_exit "Python 3 is not installed. Please run Step 00 first."
fi

# Check if template is rendered
if [[ ! -f "$CLOUD_INIT_FILE" ]]; then
    error_exit "Cloud-init configuration file not found: $CLOUD_INIT_FILE"
    log "Please run 'make render-template' first to generate the configuration."
fi

# Load VM configuration from .env file
if [[ -f ".env" ]]; then
    source .env
    VM_NAME="${VM_NAME:-golden-template}"
    VM_CPUS="${VM_CPUS:-2}"
    VM_MEMORY="${VM_MEMORY:-4G}"
    VM_DISK="${VM_DISK:-20G}"
else
    log "Warning: .env file not found, using default configuration"
    VM_NAME="golden-template"
    VM_CPUS=2
    VM_MEMORY=4G
    VM_DISK=20G
fi

log "Using VM configuration:"
log "  VM Name: $VM_NAME"
log "  CPUs: $VM_CPUS"
log "  Memory: $VM_MEMORY"
log "  Disk: $VM_DISK"
```

# Clean up existing VMs
log "Cleaning up existing VMs..."
if multipass list | grep -q "$VM_NAME"; then
    log "Found existing $VM_NAME VM, stopping and deleting..."
    if multipass list | grep -q "$VM_NAME.*Running"; then
        multipass stop "$VM_NAME" || true
    fi
    multipass delete "$VM_NAME" || true
    multipass purge || true
fi

# Create VM from rendered cloud-init
log "Creating VM: $VM_NAME"
multipass launch \
    --name "$VM_NAME" \
    --cpus "$VM_CPUS" \
    --memory "$VM_MEMORY" \
    --disk "$VM_DISK" \
    --cloud-init "$CLOUD_INIT_FILE"

# Wait for cloud-init to complete
log "Waiting for cloud-init to complete..."
timeout 300 multipass exec "$VM_NAME" -- cloud-init status --wait || error_exit "Cloud-init timed out"
```

# Verify setup
log "Verifying VM setup..."
verification_results=()

# Check Python
if multipass exec "$VM_NAME" -- python3.12 --version &> /dev/null; then
    log "✅ Python 3.12 is working"
    verification_results+=("python")
else
    log "❌ Python 3.12 verification failed"
fi

# Check UV
if multipass exec "$VM_NAME" -- uv --version &> /dev/null; then
    log "✅ UV is working"
    verification_results+=("uv")
else
    log "❌ UV verification failed"
fi

# Check Podman
if multipass exec "$VM_NAME" -- podman --version &> /dev/null; then
    log "✅ Podman is working"
    verification_results+=("podman")
else
    log "❌ Podman verification failed"
fi

# Check Git
if multipass exec "$VM_NAME" -- git --version &> /dev/null; then
    log "✅ Git is working"
    verification_results+=("git")
else
    log "❌ Git verification failed"
fi

# Check Make
if multipass exec "$VM_NAME" -- make --version &> /dev/null; then
    log "✅ Make is working"
    verification_results+=("make")
else
    log "❌ Make verification failed"
fi

# Check workspace directory
if multipass exec "$VM_NAME" -- test -d /home/ubuntu/workspace; then
    log "✅ Workspace directory exists"
    verification_results+=("workspace")
else
    log "❌ Workspace directory not found"
fi

# Check Make
if multipass exec "$VM_NAME" -- make --version &> /dev/null; then
    log "✅ Make is working"
    verification_results+=("make")
else
    log "❌ Make verification failed"
fi

# Check if all verifications passed
if [[ ${#verification_results[@]} -eq 7 ]]; then
    log "✅ All verifications passed!"
else
    log "⚠️  Some verifications failed. Continuing with snapshot creation..."
fi

# Stop VM for snapshot
log "Stopping VM for snapshot..."
multipass stop "$VM_NAME"

# Create snapshot
log "Creating golden snapshot: $SNAPSHOT_NAME"
multipass snapshot "$VM_NAME" --name "$SNAPSHOT_NAME"

# Display results
log "✅ Golden image creation completed successfully!"
log ""
log "VM Information:"
log "  VM Name: $VM_NAME"
log "  Snapshot: $VM_NAME.$SNAPSHOT_NAME"
log ""
log "Usage:"
log "  # Create new VM from snapshot"
log "  multipass launch --name my-project --snapshot $VM_NAME.$SNAPSHOT_NAME"
log ""
log "  # List available snapshots"
log "  multipass list"
log ""
log "  # Start the template VM"
log "  multipass start $VM_NAME"
log ""
log "  # Access the template VM"
log "  multipass shell $VM_NAME"
log ""
log "Template Management:"
log "  # Edit environment variables"
log "  vim .env"
log ""
log "  # Re-render template after changes"
log "  make render-template"
log ""
log "  # Create VM with new configuration"
log "  ./create-base-image.sh"
log ""
log "Next Steps:"
log "  - Proceed to Step 02: Project VM Provisioning"
log "  - Use the snapshot to create development environments"
```

## Verification Script

### `verify-base-image.sh`

```bash
#!/bin/bash
# verify-base-image.sh - Verify golden image setup

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Configuration
VM_NAME="golden-template"
SNAPSHOT_NAME="golden-image"

log "Verifying golden image setup..."

# Check if VM exists
if ! multipass list | grep -q "$VM_NAME"; then
    error_exit "Golden template VM not found. Please run create-base-image.sh first."
fi

# Check if snapshot exists
if ! multipass list | grep -q "$VM_NAME.$SNAPSHOT_NAME"; then
    error_exit "Golden snapshot not found. Please run create-base-image.sh first."
fi

# Start VM if not running
if ! multipass list | grep -q "$VM_NAME.*Running"; then
    log "Starting VM for verification..."
    multipass start "$VM_NAME"
    sleep 10  # Wait for VM to fully start
fi

# Perform comprehensive verification
log "Performing comprehensive verification..."

# System information
log "System Information:"
multipass exec "$VM_NAME" -- "uname -a"
multipass exec "$VM_NAME" -- "cat /etc/os-release"

# Python verification
log ""
log "Python Verification:"
multipass exec "$VM_NAME" -- "python3.12 --version"
multipass exec "$VM_NAME" -- "which python3.12"
multipass exec "$VM_NAME" -- "python3.12 -c 'import sys; print(sys.path)'"

# UV verification
log ""
log "UV Verification:"
multipass exec "$VM_NAME" -- "uv --version"
multipass exec "$VM_NAME" -- "which uv"
multipass exec "$VM_NAME" -- "uv pip list --system"

# Podman verification
log ""
log "Podman Verification:"
multipass exec "$VM_NAME" -- "podman --version"
multipass exec "$VM_NAME" -- "podman info"
multipass exec "$VM_NAME" -- "podman ps -a"

# Git verification
log ""
log "Git Verification:"
multipass exec "$VM_NAME" -- "git --version"
multipass exec "$VM_NAME" -- "git config --global user.name"
multipass exec "$VM_NAME" -- "git config --global user.email"

# Development tools verification
log ""
log "Development Tools Verification:"
multipass exec "$VM_NAME" -- "black --version"
multipass exec "$VM_NAME" -- "isort --version"
multipass exec "$VM_NAME" -- "flake8 --version"
multipass exec "$VM_NAME" -- "mypy --version"
multipass exec "$VM_NAME" -- "pytest --version"
multipass exec "$VM_NAME" -- "make --version"

# File system verification
log ""
log "File System Verification:"
multipass exec "$VM_NAME" -- "ls -la /home/ubuntu/"
multipass exec "$VM_NAME" -- "ls -la /home/ubuntu/workspace"
multipass exec "$VM_NAME" -- "ls -la /home/ubuntu/.bash_aliases"



# SSH access verification
log ""
log "SSH Access Verification:"
VM_IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
log "VM IP: $VM_IP"
log "SSH command: ssh ubuntu@$VM_IP"

# Performance metrics
log ""
log "Performance Metrics:"
multipass exec "$VM_NAME" -- "free -h"
multipass exec "$VM_NAME" -- "df -h"
multipass exec "$VM_NAME" -- "nproc"

# Test basic functionality
log ""
log "Basic Functionality Tests:"
multipass exec "$VM_NAME" -- "python3.12 -c 'print(\"Python test passed\")'"
multipass exec "$VM_NAME" -- "uv --help | head -5"
multipass exec "$VM_NAME" -- "podman run --rm hello-world"
multipass exec "$VM_NAME" -- "git --version"

log ""
log "✅ Golden image verification completed successfully!"
log ""
log "Summary:"
log "  VM Name: $VM_NAME"
log "  Snapshot: $VM_NAME.$SNAPSHOT_NAME"
log "  VM IP: $VM_IP"
log ""
log "The golden image is ready for use in development environments."
```

### Usage Instructions

#### 1. Setup Environment Configuration

```bash
# Copy the example environment file
cp .env.example .env

# Edit the environment file with your configuration
vim .env

# Key variables to configure:
# - GIT_NAME: Your Git display name
# - GIT_EMAIL: Your Git email address  
# - SSH_PUBLIC_KEY: Your SSH public key
# - VM_*: VM resource configuration
```

#### 2. Render Template

**Rendering the Template**:
```bash
# Install gomplate (if not already installed)
make install-gomplate

# List available templates
make list-templates

# Copy a template to use
make copy-template TEMPLATE=python
# or
make copy-template TEMPLATE=nodejs

# Configure the environment
vim .env  # Set Git name, email, SSH key

# Render the template
make render-template
# Result: cloud-init.yaml

# Or manually with gomplate
gomplate -f templates/cloud-init.j2 -d .env=.env > cloud-init.yaml
```

#### 3. Create Golden Image

```bash
./create-base-image.sh
```

#### 4. Verify Golden Image

```bash
./verify-base-image.sh
```

#### 5. Manual Verification (Optional)

```bash
# Access the VM directly
multipass shell golden-template

# Inside the VM:
python3.12 --version
uv --version
podman --version
git --version
ls -la /home/ubuntu/workspace
```

## Troubleshooting

### Common Issues

#### 1. Cloud-init Fails
```bash
# Check cloud-init logs
multipass exec golden-template -- tail -f /var/log/cloud-init.log

# Re-run cloud-init
multipass exec golden-template -- sudo cloud-init clean
multipass exec golden-template -- sudo cloud-init init
```

#### 2. Package Installation Fails
```bash
# Update package lists
multipass exec golden-template -- sudo apt update

# Fix broken packages
multipass exec golden-template -- sudo apt --fix-broken install
```

#### 3. SSH Access Issues
```bash
# Regenerate SSH key in VM
multipass exec golden-template -- ssh-keygen -f ~/.ssh/id_rsa -N ""

# Copy public key to VM
cat ~/.ssh/id_rsa.pub | multipass exec golden-template -- "tee -a ~/.ssh/authorized_keys"
```

#### 4. Snapshot Creation Fails
```bash
# Ensure VM is stopped
multipass stop golden-template

# Check VM status
multipass info golden-template

# Retry snapshot creation
multipass snapshot golden-template --name golden-image
```

### Debug Mode

Run with debug information:
```bash
# Enable verbose output
bash -x create-base-image.sh

# Or run with debug flag
DEBUG=1 ./create-base-image.sh
```

## Performance Optimization

### 1. Resource Allocation
- **CPU**: 2 cores (minimum)
- **Memory**: 4GB (minimum)
- **Disk**: 20GB (minimum)

### 2. Snapshot Efficiency
- Snapshots use copy-on-write technology
- Multiple VMs from same snapshot share base image
- Storage efficient for development environments

### 3. Network Configuration
- Multipass provides isolated network by default
- Each VM gets its own IP address
- No need for complex network setup

## Security Considerations

### 1. SSH Key Management
- Use dedicated SSH keys for VM access
- Store private keys securely
- Rotate keys periodically

### 2. User Permissions
- Limited sudo access within VMs
- Rootless container operation with Podman
- Proper file ownership

### 3. Network Security
- VMs are isolated by default
- No direct host network exposure
- Firewall rules applied at hypervisor level

## Next Steps

After completing Step 01, proceed to:

- **Step 02**: Project VM Provisioning
  - Create project-specific VMs from the golden image
  - Clone repositories and configure project environments
  - Execute development tasks using the agent system

## Best Practices

1. **Regular Updates**: Periodically recreate the golden image with updated packages
2. **Version Control**: Keep cloud-init configuration in version control
3. **Testing**: Always verify the golden image before using it for production
4. **Documentation**: Document any customizations made to the base image
5. **Backup**: Keep backup copies of important snapshots