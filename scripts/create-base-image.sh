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
CLOUD_INIT_FILE="templates/cloud-init.yaml"
SNAPSHOT_NAME="golden-image"

# Check prerequisites
log "Checking prerequisites..."
if ! command -v multipass &> /dev/null; then
    error_exit "Multipass is not installed. Please run setup-host.sh first."
fi

if ! command -v make &> /dev/null; then
    error_exit "Make is not installed. Please run setup-host.sh first."
fi

# Check if template is rendered
if [[ ! -f "$CLOUD_INIT_FILE" ]]; then
    error_exit "Cloud-init configuration file not found: $CLOUD_INIT_FILE"
    log "Please run 'make render-template' first to generate the configuration."
fi

# Load VM configuration from .env file
if [[ -f ".env" ]]; then
    source .env
    VM_NAME="${VM_NAME:-python-template}"
    VM_CPUS="${VM_CPUS:-2}"
    VM_MEMORY="${VM_MEMORY:-4G}"
    VM_DISK="${VM_DISK:-20G}"
else
    log "Warning: .env file not found, using default configuration"
    VM_NAME="python-template"
    VM_CPUS=2
    VM_MEMORY=4G
    VM_DISK=20G
fi

log "Using VM configuration:"
log "  VM Name: $VM_NAME"
log "  CPUs: $VM_CPUS"
log "  Memory: $VM_MEMORY"
log "  Disk: $VM_DISK"

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

# Check Git
if multipass exec "$VM_NAME" -- git --version &> /dev/null; then
    log "✅ Git is working"
    verification_results+=("git")
else
    log "❌ Git verification failed"
fi

# Check Podman
if multipass exec "$VM_NAME" -- podman --version &> /dev/null; then
    log "✅ Podman is working"
    verification_results+=("podman")
else
    log "❌ Podman verification failed"
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
log "Next Steps:"
log "  - Proceed to project VM provisioning"
log "  - Use the snapshot to create development environments"
