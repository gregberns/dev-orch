# Makefile for Developer Orchestration System
# This Makefile provides commands for managing the base machine setup

GOMPLATE_VERSION=v3.11.0

.PHONY: setup verify clean help install-multipass install-make install-gomplate render-template create-base-image list-templates copy-template

# Default target
help:
	@echo "Developer Orchestration System - Base Machine Commands"
	@echo ""
	@echo "Available commands:"
	@echo "  setup        - Install all prerequisites (Multipass, Make)"
	@echo "  verify       - Verify all prerequisites are installed"
	@echo "  clean        - Clean up host environment"
	@echo "  install-multipass - Install Multipass only"
	@echo "  install-make     - Install Make only"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make setup"
	@echo "  make verify"

# Install all prerequisites
setup:
	@echo "Setting up host environment..."
	@echo "Installing Multipass..."
	@if command -v multipass >/dev/null 2>&1; then \
		echo "Multipass already installed"; \
	else \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			brew install --cask multipass; \
		else \
			curl -fsSL https://multipass.run | sh; \
		fi; \
	fi
	@echo "Installing Make..."
	@if command -v make >/dev/null 2>&1; then \
		echo "Make already installed"; \
	else \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			brew install make; \
		else \
			sudo apt update && sudo apt install -y build-essential; \
		fi; \
	fi
	@echo "Host environment setup complete!"
	@echo "Run 'make verify' to verify installation."

# Verify all prerequisites
verify:
	@echo "Verifying host environment..."
	@echo ""
	@echo "Checking Multipass..."
	@if command -v multipass >/dev/null 2>&1; then \
		echo "✅ Multipass: $$(multipass --version)"; \
	else \
		echo "❌ Multipass: NOT INSTALLED"; \
	fi
	@echo ""
	@echo "Checking Make..."
	@if command -v make >/dev/null 2>&1; then \
		echo "✅ Make: $$(make --version | head -n1)"; \
	else \
		echo "❌ Make: NOT INSTALLED"; \
	fi
	@echo ""
	@echo "Verification complete!"

# Clean up host environment
clean:
	@echo "Cleaning up host environment..."
	@echo "Note: This does not clean up VMs. Use 'multipass purge' for that."
	@echo "Host environment cleanup complete!"

# Install Multipass only
install-multipass:
	@echo "Installing Multipass..."
	@if command -v multipass >/dev/null 2>&1; then \
		echo "Multipass already installed: $$(multipass --version)"; \
	else \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			brew install --cask multipass; \
		else \
			curl -fsSL https://multipass.run | sh; \
		fi; \
	fi
	@echo "Multipass installation complete!"

# Install Make only
install-make:
	@echo "Installing Make..."
	@if command -v make >/dev/null 2>&1; then \
		echo "Make already installed: $$(make --version | head -n1)"; \
	else \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			brew install make; \
		else \
			sudo apt update && sudo apt install -y build-essential; \
		fi; \
	fi
	@echo "Make installation complete!"

# Install gomplate only
install-gomplate:
	@echo "Installing gomplate..."
	@if command -v gomplate >/dev/null 2>&1; then \
		echo "gomplate already installed: $$(gomplate --version)"; \
	else \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			brew install gomplate; \
		else \
			# For Linux, download binary directly
			curl -sSL https://github.com/hairyhenderson/gomplate/releases/download/$(GOMPLATE_VERSION)/gomplate_$(GOMPLATE_VERSION)_linux_$(uname -m).tar.gz | tar -xz -C /tmp/; \
			sudo mv /tmp/gomplate /usr/local/bin/; \
			rm -f /tmp/gomplate.1; \
		fi; \
	fi
	@echo "gomplate installation complete!"

# Check if we're on the correct platform
check-platform:
	@if [[ "$$(uname)" != "Darwin" && "$$(uname)" != "Linux" ]]; then \
		echo "❌ Error: This system only supports macOS and Linux"; \
		echo "Current platform: $$(uname)"; \
		exit 1; \
	fi
	@echo "✅ Platform check passed: $$(uname)"

# Setup with platform check
setup-safe:
	@echo "Performing safe setup with platform check..."
	@make check-platform
	@make setup

# Verify with platform check
verify-safe:
	@echo "Performing safe verification with platform check..."
	@make check-platform
	@make verify

# Show system information
info:
	@echo "System Information:"
	@echo "  Platform: $$(uname)"
	@echo "  Architecture: $$(uname -m)"
	@echo "  Kernel: $$(uname -r)"
	@echo ""
	@echo "Prerequisites:"
	@echo "  Multipass: $$(command -v multipass >/dev/null 2>&1 && echo "$$(multipass --version)" || echo "NOT INSTALLED")"
	@echo "  Make: $$(command -v make >/dev/null 2>&1 && echo "$$(make --version | head -n1)" || echo "NOT INSTALLED")"
	@echo ""
	@echo "VM Status:"
	@multipass list 2>/dev/null || echo "Multipass not available"

# Quick setup for development
quick-setup:
	@echo "Quick setup for development..."
	@make check-platform
	@make setup
	@make install-gomplate
	@echo ""
	@echo "Next steps:"
	@echo "1. Run 'make verify' to confirm setup"
	@echo "2. Copy .env.example to .env and configure"
	@echo "3. Run 'make render-template' to generate cloud-init.yaml"
	@echo "4. Run 'make create-base-image' to create VM base image"
	@echo "5. Run 'make info' to check system status"



# Create base VM image using rendered template
create-base-image:
	@echo "Creating base VM image..."
	@if [ ! -f cloud-init.yaml ]; then \
		echo "Error: cloud-init.yaml not found. Run 'make render-template' first."; \
		exit 1; \
	fi
	@echo "Using configuration from cloud-init.yaml"
	@echo "VM name: $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2)"
	@echo "CPUs: $$(grep -o 'VM_CPUS=[^ ]*' .env | cut -d'=' -f2)"
	@echo "Memory: $$(grep -o 'VM_MEMORY=[^ ]*' .env | cut -d'=' -f2)"
	@echo "Disk: $$(grep -o 'VM_DISK=[^ ]*' .env | cut -d'=' -f2)"
	@echo ""
	@echo "To create the VM, run:"
	@echo "  multipass launch --name $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2) --cpus $$(grep -o 'VM_CPUS=[^ ]*' .env | cut -d'=' -f2) --memory $$(grep -o 'VM_MEMORY=[^ ]*' .env | cut -d'=' -f2) --disk $$(grep -o 'VM_DISK=[^ ]*' .env | cut -d'=' -f2) --cloud-init cloud-init.yaml"
	@echo ""
	@echo "Then wait for cloud-init to complete:"
	@echo "  multipass exec $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2) -- cloud-init status --wait"
	@echo ""
	@echo "Finally, create a snapshot:"
	@echo "  multipass snapshot $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2) --name golden-image"

# List all VMs
list-vms:
	@echo "Multipass VMs:"
	@multipass list 2>/dev/null || echo "Multipass not available"

# Stop all VMs
stop-all-vms:
	@echo "Stopping all running VMs..."
	@multipass stop --all 2>/dev/null || echo "No VMs to stop or Multipass not available"

# Delete all VMs
delete-all-vms:
	@echo "Deleting all VMs..."
	@multipass delete --all 2>/dev/null || echo "No VMs to delete or Multipass not available"
	@multipass purge 2>/dev/null || echo "No VMs to purge or Multipass not available"
	@echo "All VMs deleted and purged"

# Show help with examples
help-examples:
	@echo "Developer Orchestration System - Usage Examples"
	@echo ""
	@echo "Basic Setup:"
	@echo "  make setup                    # Install all prerequisites"
	@echo "  make verify                   # Verify installation"
	@echo "  make info                     # Show system information"
	@echo ""
	@echo "Individual Components:"
	@echo "  make install-multipass        # Install Multipass only"
	@echo "  make install-make             # Install Make only"
	@echo "  make install-gomplate         # Install gomplate only"
	@echo ""
	@echo "Template Management:"
	@echo "  make render-template          # Render cloud-init template from .env"
	@echo "  make show-template            # Show template variables"
	@echo ""
	@echo "VM Management:"
	@echo "  make list-vms                 # List all VMs"
	@echo "  make stop-all-vms             # Stop all VMs"
	@echo "  make delete-all-vms           # Delete and purge all VMs"
	@echo ""
	@echo "Template Management:"
	@echo "  make list-templates           # List available templates"
	@echo "  make copy-template            # Copy a template to use"
	@echo "  make render-template          # Render current template"
	@echo "  make create-base-image        # Create VM from current template"
	@echo ""
	@echo "Development Workflow:"
	@echo "  make quick-setup              # Quick setup with platform check"
	@echo "  make copy-template TEMPLATE=python  # Copy Python template"
	@echo "  make copy-template TEMPLATE=nodejs  # Copy Node.js template"
	@echo "  make render-template          # Render current template"
	@echo "  make create-base-image        # Create VM from current template"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean                    # Clean up host environment"
	@echo "  make help                     # Show basic help"
	@echo "  make help-examples            # Show this extended help"

# Render cloud-init template from environment variables using gomplate
render-template:
	@echo "Rendering cloud-init template with gomplate..."
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Please copy .env.example to .env and configure."; \
		exit 1; \
	fi
	@if ! command -v gomplate >/dev/null 2>&1; then \
		echo "Error: gomplate is required for template rendering."; \
		echo "Run 'make install-gomplate' to install it."; \
		exit 1; \
	fi
	@echo "Rendering cloud-init.j2 to cloud-init.yaml..."
	@gomplate -f templates/cloud-init.j2 -d .env=.env > cloud-init.yaml
	@echo "✅ Template rendered successfully: cloud-init.yaml"

# Render Node.js template from environment variables using gomplate
render-nodejs:
	@echo "Rendering Node.js template with gomplate..."
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Please copy .env.nodejs.example to .env and configure."; \
		exit 1; \
	fi
	@if ! command -v gomplate >/dev/null 2>&1; then \
		echo "Error: gomplate is required for template rendering."; \
		echo "Run 'make install-gomplate' to install it."; \
		exit 1; \
	fi
	@echo "Rendering cloud-init-nodejs.j2 to cloud-init-nodejs.yaml..."
	@gomplate -f cloud-init-nodejs.j2 -d .env=.env > cloud-init-nodejs.yaml
	@echo "✅ Node.js template rendered successfully: cloud-init-nodejs.yaml"

 # Show template variables
show-template:
	@echo "Template variables (from .env file):"
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Please copy .env.example to .env and configure."; \
		exit 1; \
	fi
	@echo ""
	@grep -v '^#' .env | grep -v '^$$' | while IFS='=' read -r key value; do \
		echo "  $$=$$value"; \
	done

# Create base VM image using rendered template
# Create base VM image using rendered template
create-base-image:
	@echo "Creating base VM image..."
	@if [ ! -f cloud-init.yaml ]; then \
		echo "Error: cloud-init.yaml not found. Run 'make render-template' first."; \
		exit 1; \
	fi
	@echo "Using configuration from cloud-init.yaml"
	@echo "VM name: $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2)"
	@echo "CPUs: $$(grep -o 'VM_CPUS=[^ ]*' .env | cut -d'=' -f2)"
	@echo "Memory: $$(grep -o 'VM_MEMORY=[^ ]*' .env | cut -d'=' -f2)"
	@echo "Disk: $$(grep -o 'VM_DISK=[^ ]*' .env | cut -d'=' -f2)"
	@echo ""
	@echo "To create the VM, run:"
	@echo "  multipass launch --name $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2) --cpus $$(grep -o 'VM_CPUS=[^ ]*' .env | cut -d'=' -f2) --memory $$(grep -o 'VM_MEMORY=[^ ]*' .env | cut -d'=' -f2) --disk $$(grep -o 'VM_DISK=[^ ]*' .env | cut -d'=' -f2) --cloud-init cloud-init.yaml"
	@echo ""
	@echo "Then wait for cloud-init to complete:"
	@echo "  multipass exec $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2) -- cloud-init status --wait"
	@echo ""
	@echo "Finally, create a snapshot:"
	@echo "  multipass snapshot $$(grep -o 'VM_NAME=[^ ]*' .env | cut -d'=' -f2) --name golden-image"

# List available templates
list-templates:
	@echo "Available templates in template-examples/:"
	@echo ""
	@ls -1 template-examples/ | grep -E '\.(j2|example)$$' | while read file; do \
		if [[ "$$file" == *.j2 ]]; then \
			template_name=$$(basename "$$file" .j2); \
			env_file="template-examples/.env.$$template_name.example"; \
			if [[ -f "$$env_file" ]]; then \
				echo "  $$template_name (with .env support)"; \
			else \
				echo "  $$template_name"; \
			fi; \
		elif [[ "$$file" == .env.*.example ]]; then \
			template_name=$$(echo "$$file" | sed 's/\.env\.//; s/\.example$$//'); \
			if [[ -f "template-examples/cloud-init-$$template_name.j2" ]]; then \
				echo "  $$template_name (with cloud-init support)"; \
			fi; \
		fi; \
	done
	@echo ""
	@echo "To use a template, run:"
	@echo "  make copy-template TEMPLATE=<template-name>"

# Copy a template to use
copy-template:
	@if [[ -z "$(TEMPLATE)" ]]; then \
		echo "Error: TEMPLATE variable is required."; \
		echo "Available templates:"; \
		make list-templates; \
		exit 1; \
	fi
	@if [[ ! -f "template-examples/cloud-init-$(TEMPLATE).j2" ]]; then \
		echo "Error: Template '$(TEMPLATE)' not found."; \
		echo "Available templates:"; \
		make list-templates; \
		exit 1; \
	fi
	@echo "Copying template '$(TEMPLATE)' to templates/..."
	@cp "template-examples/cloud-init-$(TEMPLATE).j2" "templates/"
	@if [[ -f "template-examples/.env.$(TEMPLATE).example" ]]; then \
		cp "template-examples/.env.$(TEMPLATE).example" ".env"; \
		echo "Copied .env.$(TEMPLATE).example to .env"; \
		echo "Please edit .env with your configuration before rendering."; \
	else \
		echo "Template '$(TEMPLATE)' copied."; \
		echo "Please create a .env file with your configuration before rendering."; \
	fi
	@echo ""
	@echo "Template '$(TEMPLATE)' is ready to use!"
	@echo "Run 'make render-template' to generate cloud-init.yaml"

# Quick template setup
setup-template:
	@echo "Setting up template configuration..."
	@if [ ! -f .env ]; then \
		echo "Copying .env.example to .env..."; \
		cp .env.example .env; \
	fi
	@echo "Please edit .env with your configuration:"
	@echo "  - GIT_NAME: Your Git display name"
	@echo "  - GIT_EMAIL: Your Git email address"
	@echo "  - SSH_PUBLIC_KEY: Your SSH public key"
	@echo "  - VM_*: VM configuration options"
	@echo ""
	@echo "After editing .env, run:"
	@echo "  make render-template"
	@echo "  make create-base-image"
