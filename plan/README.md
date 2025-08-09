# Developer Orchestration System - Plan

## Overview

This plan outlines a developer orchestration system that automates the creation, configuration, and teardown of isolated development environments using Multipass VMs. The system provides reproducible environments with consistent tooling and efficient resource management.

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Host Machine  │    │  Multipass VM   │    │   Agent System  │
│                 │    │                 │    │                 │
│  • Multipass    │    │  • Template VM  │    │  • Task Exec    │
│  • Make         │    │  • Dev Tools    │    │  • SSH Comm     │
│  • gomplate     │    │  • Environment  │    │  • Output Cap   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Setup Process

### Step 00: Base Machine Setup

**Requirements**: Install Multipass and Make on the host machine.

```bash
# Using Makefile (Recommended)
make setup          # Install all prerequisites
make verify         # Verify installation

# Or using direct scripts
./setup-host.sh     # Install Multipass and Make
./verify-host.sh    # Verify installation
```

**Note**: Python, UV, Git, and Podman will be installed in the VM, not on the host.

### Step 01: VM Configuration Setup

The VM configuration uses gomplate with environment variables for flexibility. Choose from template examples or create your own custom templates.

**Template System:**

- **template-examples/**: Starter templates for different development environments
- **templates/**: Active templates you're currently using
- **Flexible**: Copy, modify, and create custom templates as needed

**Available Template Examples:**
```bash
# Install gomplate (one-time)
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
```

### Key Components

#### 1. Base Environment Setup (Step 00)
- **Purpose**: Ensure base machine has minimal prerequisites
- **Scope**: macOS and Linux only
- **Idempotency**: Safe to run multiple times
- **Components**: Multipass, Make, gomplate

#### 2. Base VM Image Creation (Step 01)
- **Purpose**: Create reproducible golden VM images with all dev tools
- **Technology**: Multipass snapshots with cloud-init
- **Base Image**: Ubuntu 22.04 LTS
- **Template Options**: Python or Node.js developer environments

### 3. VM Lifecycle Management
- **Provisioning**: Create VMs from golden snapshots
- **Configuration**: Apply project-specific settings
- **Execution**: Run tasks within isolated environments
- **Teardown**: Clean up resources after completion

### 4. Agent Execution Framework
- **Communication**: SSH-based task execution
- **Task Management**: JSON-configurable task definitions
- **Output Handling**: Capture and return results
- **Error Handling**: Robust error detection and reporting

## Template System

### Cloud-Init Template (`cloud-init.j2`)
The configuration template uses gomplate syntax for variable substitution:

```yaml
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - {{ env "SSH_PUBLIC_KEY" }}
write_files:
  - path: /home/ubuntu/.gitconfig
    content: |
      [user]
          name = {{ env "GIT_NAME" }}
          email = {{ env "GIT_EMAIL" }}
```

### Environment Configuration (`.env`)
```bash
# Git configuration
GIT_NAME="Developer Name"
GIT_EMAIL="developer@example.com"

# SSH configuration
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2E..."

# VM configuration
VM_NAME="golden-template"
VM_CPUS=2
VM_MEMORY=4G
VM_DISK=20G
```

## Example Workflows

### Python Project Setup
```bash
# Step 1: Setup host environment
make setup

# Step 2: Install gomplate
make install-gomplate

# Step 3: Copy Python template
make copy-template TEMPLATE=python

# Step 4: Configure environment
vim .env  # Set Git name, email, SSH key

# Step 5: Render template
make render-template

# Step 6: Create base image
./create-base-image.sh

# Step 6: Provision project VM
./provision-project-vm.sh my-python-project https://github.com/user/python-repo.git

# Step 7: Run agent tasks
python3 agent_executor.py dev-my-python-project python-tasks.json
```

### Node.js Project Setup
```bash
# Step 1: Setup host environment
make setup

# Step 2: Install gomplate
make install-gomplate

# Step 3: Copy Node.js template
make copy-template TEMPLATE=nodejs

# Step 4: Configure environment
vim .env  # Set Git name, email, SSH key

# Step 5: Render template
make render-template

# Step 6: Create base image
./create-base-image.sh

# Step 7: Provision project VM
./provision-project-vm.sh my-nodejs-project https://github.com/user/nodejs-repo.git

# Step 8: Run agent tasks
python3 agent_executor.py dev-my-nodejs-project nodejs-tasks.json
```

### Quick Development Setup
```bash
# Python environment
make setup && \
make install-gomplate && \
make copy-template TEMPLATE=python && \
vim .env && \
make render-template && \
./create-base-image.sh

# Node.js environment  
make setup && \
make install-gomplate && \
make copy-template TEMPLATE=nodejs && \
vim .env && \
make render-template && \
./create-base-image.sh
```

## File Structure

```
./plan/
├── README.md                    # This plan documentation
├── 00-environment-setup.md     # Step 00: Host setup guide
├── 01-base-vm-setup.md         # Step 01: VM setup guide
├── SUMMARY.md                   # Comprehensive summary
├── Makefile                     # Build and template management
├── setup-host.sh                # Host installation script
├── verify-host.sh               # Host verification script
├── create-base-image.sh         # VM creation script
├── verify-base-image.sh         # VM verification script
├── templates/                   # Active templates directory
│   ├── cloud-init.j2           # Default Python template
│   └── .env.example            # Default environment template
└── template-examples/           # Template examples directory
    ├── cloud-init.j2           # Python developer environment
    ├── .env.example            # Python environment config
    ├── cloud-init-nodejs.j2    # Node.js developer environment
    └── .env.nodejs.example     # Node.js environment config
```

## Essential Commands

### Host Management
```bash
make setup                    # Install prerequisites
make verify                   # Verify installation
make install-gomplate         # Install gomplate
make clean                    # Clean up host
```

### Template Management
```bash
make list-templates           # List available templates
make copy-template            # Copy a template to use
make render-template          # Render current template
```

### Template Management
```bash
make render-template    # Render cloud-init template
make show-template      # Show template variables
make setup-template     # Quick template setup
```

### VM Management
```bash
multipass list          # List VMs
multipass launch --name vm1 --snapshot golden-template.golden-image
multipass shell vm1     # Access VM
multipass stop vm1      # Stop VM
multipass delete vm1    # Delete VM
```

## Technical Specifications

### Host Requirements
- **Operating System**: macOS or Linux
- **Memory**: 8GB minimum (16GB recommended)
- **Storage**: 50GB minimum (100GB recommended)
- **Network**: Internet connection
- **Prerequisites**: Multipass, Make, gomplate

### Template System

#### Template Examples
- **Python**: Python 3.12, UV, pip, virtual environments, Python dev tools
- **Node.js**: Node.js 20.x, npm, yarn, pnpm, JavaScript/TypeScript dev tools

#### Creating Custom Templates
1. Copy an example template: `make copy-template TEMPLATE=python`
2. Modify the template files in `templates/`
3. Configure the `.env` file with your settings
4. Render with: `make render-template`
5. Create VM with: `./create-base-image.sh`

## Security Considerations

- **SSH Key Management**: Dedicated SSH keys for VM access
- **Network Isolation**: VM-level network separation
- **Container Security**: Rootless Podman operation
- **Data Protection**: Automatic cleanup of sensitive data

## Best Practices

1. **Regular Updates**: Periodically recreate golden images
2. **Version Control**: Keep configurations in version control
3. **Testing**: Always verify environments before use
4. **Documentation**: Document customizations and workflows
5. **Monitoring**: Track resource usage and performance

## Next Steps

1. Complete Step 00: Base machine setup
2. Complete Step 01: VM configuration and golden image creation
3. Implement VM provisioning system
4. Develop agent execution framework
5. Create example workflows and documentation

---

This plan provides a solid foundation for building a developer orchestration system that ensures consistent, reproducible development environments while maintaining efficiency and security.