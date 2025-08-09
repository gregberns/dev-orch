# Create a comprehensive Multipass setup guide
guide_content = """# Multipass Setup Guide: VM Management with Podman

## Overview
This guide provides complete instructions for setting up Multipass on macOS to manage Linux VMs with Docker-like workflow. Each VM can run containerized applications (like PostgreSQL) with full isolation and easy management.

## Table of Contents
1. [Installation](#installation)
2. [Basic Setup](#basic-setup)
3. [VM Configuration with Podman](#vm-configuration-with-podman)
4. [VSCode Integration](#vscode-integration)
5. [Common Operations](#common-operations)
6. [Example Workflows](#example-workflows)
7. [Troubleshooting](#troubleshooting)

---

## Installation

### Install Multipass
```bash
# Install via Homebrew
brew install --cask multipass

# Verify installation
multipass version
```

### Install VSCode Remote-SSH Extension
```bash
# Install Remote-SSH extension
code --install-extension ms-vscode-remote.remote-ssh
```

---

## Basic Setup

### Create SSH Key (if needed)
```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

### Basic VM Commands
```bash
# List available Ubuntu images
multipass find

# Launch a basic VM
multipass launch --name test-vm --cpus 2 --memory 4G --disk 20G

# List running VMs
multipass list

# Get VM information
multipass info test-vm

# Execute commands in VM
multipass exec test-vm -- uname -a

# Get shell access
multipass shell test-vm

# Stop/Start/Delete VMs
multipass stop test-vm
multipass start test-vm
multipass delete test-vm
multipass purge  # Permanently remove deleted VMs
```

---

## VM Configuration with Podman

### Create Cloud-Init Configuration
Create a file called `podman-setup.yaml`:

```yaml
#cloud-config
package_update: true
packages:
  - podman
  - podman-compose
  - git
  - curl
  - vim

users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']

runcmd:
  # Enable podman socket for rootless operation
  - systemctl --user enable podman.socket --now
  - loginctl enable-linger ubuntu

  # Create workspace directory
  - mkdir -p /home/ubuntu/workspace
  - chown ubuntu:ubuntu /home/ubuntu/workspace

write_files:
  - path: /home/ubuntu/.bashrc_append
    content: |
      # Podman aliases for Docker-like experience
      alias docker='podman'
      alias docker-compose='podman-compose'
    append: true
    owner: ubuntu:ubuntu

final_message: "VM setup complete! Podman is ready for rootless containers."
```

### Launch VM with Configuration
```bash
# Launch VM with Podman setup
multipass launch --name dev-vm --cpus 2 --memory 4G --disk 20G --cloud-init podman-setup.yaml

# Wait for cloud-init to complete (check status)
multipass exec dev-vm -- cloud-init status --wait
```

---

## VSCode Integration

### Configure SSH Access
```bash
# Get VM IP address
VM_IP=$(multipass info dev-vm | grep IPv4 | awk '{print $2}')
echo "VM IP: $VM_IP"

# Copy SSH key to VM
multipass exec dev-vm -- bash -c "mkdir -p ~/.ssh && echo '$(cat ~/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys"
```

### Add SSH Config
Add to your `~/.ssh/config`:
```bash
Host dev-vm
  HostName 192.168.64.X  # Replace with your VM's IP
  User ubuntu
  IdentityFile ~/.ssh/id_rsa
  ServerAliveInterval 120
```

### Connect VSCode
```bash
# Open VSCode and connect to VM
# Cmd+Shift+P → "Remote-SSH: Connect to Host" → Select "dev-vm"
# Or use command line:
code --remote ssh-remote+dev-vm /home/ubuntu/workspace
```

---

## Common Operations

### File Mounting (VM ↔ Host)
```bash
# Create host directory for VM data
mkdir -p ~/multipass-vms/dev-vm

# Mount VM directory to host (for accessing VM files from macOS)
multipass mount dev-vm:/home/ubuntu/workspace ~/multipass-vms/dev-vm

# Mount host directory to VM (for sharing files from macOS to VM)
multipass mount ~/projects dev-vm:/home/ubuntu/host-projects

# List active mounts
multipass info dev-vm | grep Mounts
```

### Container Management in VM
```bash
# Run a simple container
multipass exec dev-vm -- podman run --rm -it ubuntu:22.04 echo "Hello from container"

# Run PostgreSQL container
multipass exec dev-vm -- podman run -d \\
  --name postgres \\
  -e POSTGRES_PASSWORD=mysecret \\
  -v pgdata:/var/lib/postgresql/data \\
  -p 5432:5432 \\
  postgres:15

# List running containers
multipass exec dev-vm -- podman ps

# View container logs
multipass exec dev-vm -- podman logs postgres

# Stop and remove container
multipass exec dev-vm -- podman stop postgres
multipass exec dev-vm -- podman rm postgres
```

---

## Example Workflows

### Workflow 1: Development Environment with Database

#### 1. Create VM Configuration (`dev-env.yaml`)
```yaml
#cloud-config
package_update: true
packages:
  - podman
  - podman-compose
  - nodejs
  - npm
  - git

write_files:
  - path: /home/ubuntu/docker-compose.yml
    content: |
      version: '3.8'
      services:
        postgres:
          image: postgres:15
          environment:
            POSTGRES_DB: myapp
            POSTGRES_USER: developer
            POSTGRES_PASSWORD: devpass123
          volumes:
            - pgdata:/var/lib/postgresql/data
          ports:
            - "5432:5432"
        redis:
          image: redis:7
          ports:
            - "6379:6379"
      volumes:
        pgdata:
    owner: ubuntu:ubuntu

runcmd:
  - chown -R ubuntu:ubuntu /home/ubuntu
```

#### 2. Launch and Setup
```bash
# Launch VM
multipass launch --name app-dev --cpus 4 --memory 8G --cloud-init dev-env.yaml

# Wait for setup
multipass exec app-dev -- cloud-init status --wait

# Create host directory and mount
mkdir -p ~/multipass-vms/app-dev
multipass mount app-dev:/home/ubuntu/workspace ~/multipass-vms/app-dev

# Start services
multipass exec app-dev -- podman-compose up -d

# Verify services
multipass exec app-dev -- podman ps
```

#### 3. Connect and Develop
```bash
# Connect VSCode
code --remote ssh-remote+app-dev /home/ubuntu/workspace

# Or get shell
multipass shell app-dev
```

### Workflow 2: Quick PostgreSQL Instance

#### Create Script (`quick-postgres.sh`)
```bash
#!/bin/bash
VM_NAME="pg-${1:-$(date +%s)}"
HOST_DIR="$HOME/multipass-vms/$VM_NAME"

echo "Creating PostgreSQL VM: $VM_NAME"

# Launch VM
multipass launch --name "$VM_NAME" --cpus 2 --memory 4G

# Install Podman
multipass exec "$VM_NAME" -- bash -c "
  sudo apt update && sudo apt install -y podman
  mkdir -p /home/ubuntu/pgdata
"

# Create host directory and mount
mkdir -p "$HOST_DIR"
multipass mount "$VM_NAME:/home/ubuntu" "$HOST_DIR"

# Start PostgreSQL
multipass exec "$VM_NAME" -- podman run -d \\
  --name postgres \\
  -e POSTGRES_PASSWORD=secret123 \\
  -v /home/ubuntu/pgdata:/var/lib/postgresql/data \\
  -p 5432:5432 \\
  postgres:15

VM_IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')

echo "PostgreSQL VM '$VM_NAME' ready!"
echo "Connection: psql -h $VM_IP -U postgres"
echo "Data location: $HOST_DIR/pgdata"
echo "Stop VM: multipass stop $VM_NAME"
echo "Delete VM: multipass delete $VM_NAME && multipass purge"
```

Usage:
```bash
chmod +x quick-postgres.sh
./quick-postgres.sh my-project
```

---

## Management Scripts

### VM Lifecycle Script (`vm-manager.sh`)
```bash
#!/bin/bash

VM_NAME="$1"
ACTION="$2"

case "$ACTION" in
  create)
    echo "Creating VM: $VM_NAME"
    multipass launch --name "$VM_NAME" --cpus 2 --memory 4G --disk 20G
    multipass exec "$VM_NAME" -- sudo apt update
    multipass exec "$VM_NAME" -- sudo apt install -y podman
    ;;
  start)
    echo "Starting VM: $VM_NAME"
    multipass start "$VM_NAME"
    ;;
  stop)
    echo "Stopping VM: $VM_NAME"
    multipass stop "$VM_NAME"
    ;;
  delete)
    echo "Deleting VM: $VM_NAME"
    multipass delete "$VM_NAME"
    multipass purge
    ;;
  shell)
    echo "Connecting to VM: $VM_NAME"
    multipass shell "$VM_NAME"
    ;;
  info)
    multipass info "$VM_NAME"
    ;;
  *)
    echo "Usage: $0 <vm-name> <create|start|stop|delete|shell|info>"
    ;;
esac
```

Usage:
```bash
chmod +x vm-manager.sh
./vm-manager.sh my-vm create
./vm-manager.sh my-vm start
./vm-manager.sh my-vm shell
./vm-manager.sh my-vm stop
```

---

## Troubleshooting

### Common Issues

#### VM Won't Start
```bash
# Check VM status
multipass list

# View VM logs
multipass exec vm-name -- dmesg

# Restart Multipass daemon (macOS)
sudo launchctl stop com.canonical.multipass.multipassd
sudo launchctl start com.canonical.multipass.multipassd
```

#### SSH Connection Issues
```bash
# Regenerate SSH key in VM
multipass exec vm-name -- ssh-keygen -f ~/.ssh/id_rsa -N ""

# Re-copy public key
multipass exec vm-name -- bash -c "echo '$(cat ~/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys"
```

#### Container Issues
```bash
# Check Podman status
multipass exec vm-name -- systemctl --user status podman

# Restart Podman service
multipass exec vm-name -- systemctl --user restart podman

# Check container logs
multipass exec vm-name -- podman logs container-name
```

#### Mount Issues
```bash
# Unmount and remount
multipass umount vm-name
multipass mount vm-name:/path/to/source ~/local/path

# Check mount permissions
multipass exec vm-name -- ls -la /mounted/path
```

### Performance Tips

1. **Resource Allocation**: Start with 2 CPUs and 4GB RAM, adjust based on workload
2. **Disk Space**: Use at least 20GB for development VMs
3. **Multiple VMs**: Stop unused VMs to save resources
4. **Container Storage**: Use volumes for persistent data

### Cleaning Up
```bash
# Stop all VMs
multipass list | grep Running | awk '{print $1}' | xargs -I {} multipass stop {}

# Delete all VMs
multipass delete --all
multipass purge

# Clean up host directories
rm -rf ~/multipass-vms/*
```

---

## Quick Reference

### Essential Commands
```bash
# VM Management
multipass launch --name NAME
multipass list
multipass info NAME
multipass shell NAME
multipass stop/start/delete NAME

# File Operations
multipass mount SOURCE TARGET
multipass transfer FILE VM:/path
multipass umount VM

# Container Operations (inside VM)
podman run -d --name NAME IMAGE
podman ps
podman logs NAME
podman stop/start/rm NAME
```

### Default Locations
- VM Storage: `~/Library/Application Support/multipassd/`
- SSH Config: `~/.ssh/config`
- Cloud-init logs: `/var/log/cloud-init.log` (in VM)

This guide provides everything needed to get started with Multipass for VM-based development with containerized applications.
"""

# Write to file
with open('multipass_setup_guide.md', 'w') as f:
    f.write(guide_content)

print("✅ Created comprehensive Multipass setup guide: multipass_setup_guide.md")
print("\nFile contains:")
print("- Complete installation instructions")
print("- VM configuration with Podman")
print("- VSCode remote development setup")
print("- File mounting (bidirectional)")
print("- Example workflows and scripts")
print("- Troubleshooting section")
print("- Quick reference commands")
