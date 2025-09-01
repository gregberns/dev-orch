# Makefile for Developer Orchestration System
# This Makefile provides commands for managing the base machine setup and VM templates

GOMPLATE_VERSION=v3.11.0

# Load environment variables from .env file if it exists
ifneq ($(wildcard .env),)
include .env
export
endif

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
	@echo "  install-gomplate - Install gomplate only"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Kestra Commands:"
	@echo "  kestra-help     - Show help for Kestra flow management"
	@echo "  kestra-validate - Validate all flows in the kestra-flows directory"
	@echo "  kestra-deploy   - Deploy all flows to the configured Kestra namespace"
	@echo ""
	@echo "Example usage:"
	@echo "  make setup"
	@echo "  make verify"
	@echo "  make kestra-validate"


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
		uname_value=$$(uname); \
		if [ "$$uname_value" = "Darwin" ]; then \
			brew install gomplate; \
		else \
			curl -sSL https://github.com/hairyhenderson/gomplate/releases/download/$(GOMPLATE_VERSION)/gomplate_$(GOMPLATE_VERSION)_linux_$$(uname -m).tar.gz | tar -xz -C /tmp/; \
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
	@echo "2. Run 'make list-templates' to see available templates"
	@echo "3. Run 'make copy-template TEMPLATE=<template-name>' to copy a template"
	@echo "4. Configure the copied .env file"
	@echo "5. Run 'make render-template' to generate cloud-init.yaml"
	@echo "6. Run 'make create-base-image' to create VM base image"
	@echo "7. Run 'make info' to check system status"

create-base-image:
	@echo "Creating base VM image..."
	@if [ ! -f templates/cloud-init.yaml ]; then \
		echo "Error: templates/cloud-init.yaml not found. Run 'make render-template' first."; \
		exit 1; \
	fi
	@echo "Using configuration from templates/cloud-init.yaml"
	@if [ -f ".env" ]; then \
		set -a; source .env; set +a; \
		VM_NAME="$${VM_NAME}"; \
	else \
		VM_NAME="python-template"; \
	fi; \
	echo "VM name: $$VM_NAME"; \
	echo ""; \
	echo "To create the VM, run:"; \
	echo "  multipass launch --name $$VM_NAME --cloud-init templates/cloud-init.yaml"; \
	echo ""; \
	echo "Then wait for cloud-init to complete:"; \
	echo "  multipass exec $$VM_NAME -- cloud-init status --wait"; \
	echo ""; \
	echo "Finally, create a snapshot:"; \
	echo "  multipass snapshot $$VM_NAME --name golden-image"

start-vm:
	@echo "Creating base VM image..."
	@echo "VM name: $${VM_NAME}";
	@multipass launch --name $$VM_NAME --cloud-init templates/cloud-init.yaml

transfer-ssh:
	@echo "Transfering local SSH key to VM"
	@multipass transfer ~/.ssh/id_rsa $$VM_NAME:/home/ubuntu/.ssh/

rebuild-vm:
	@echo "Delete VM"
	@multipass delete python-template
	@echo "Purge VMs"
	@multipass purge
	@echo "Launch new model"
	@multipass launch --name python-template --cloud-init templates/cloud-init.yaml --disk 80G
	@make transfer-ssh VM_NAME=python-template
	@echo "Copy Dev-Setup script"
	@multipass transfer ./env-specific/dev-setup.sh python-template:/home/ubuntu/
	@multipass transfer ./env-specific/.env python-template:/home/ubuntu/dev/sidegig-api
	@echo "Run the following command to start the shell:"
	@echo "  > multipass shell python-template"

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

# List available templates
list-templates:
	@echo "Available templates in template-examples/:"
	@echo ""
	@ls -1 template-examples/ | grep -E '\.(tmpl|example)$$' | while read file; do \
		if [[ "$$file" == *.tmpl ]]; then \
			template_name=$$(basename "$$file" .tmpl); \
			env_file="template-examples/.env.$$template_name.example"; \
			if [[ -f "$$env_file" ]]; then \
				echo "  $$template_name (with .env support)"; \
			else \
				echo "  $$template_name"; \
			fi; \
		elif [[ "$$file" == .env.*.example ]]; then \
			template_name=$$(echo "$$file" | sed 's/\.env\.//; s/\.example$$//'); \
			if [[ -f "template-examples/cloud-init-$$template_name.tmpl" ]]; then \
				echo "  $$template_name (with cloud-init support)"; \
			fi; \
		fi; \
	done
	@echo ""
	@echo "To use a template, run:"
	@echo "  make copy-template TEMPLATE=<template-name>"

# Copy a template to use
copy-template:
	@if [ -z "$(TEMPLATE)" ]; then \
		echo "Error: TEMPLATE variable is required."; \
		echo "Available templates:"; \
		make list-templates; \
		exit 1; \
	fi
	@if [ ! -f "template-examples/cloud-init-$(TEMPLATE).tmpl" ]; then \
		echo "Error: Template '$(TEMPLATE)' not found."; \
		echo "Available templates:"; \
		make list-templates; \
		exit 1; \
	fi
	@echo "Copying template '$(TEMPLATE)' to templates/..."
	@cp "template-examples/cloud-init-$(TEMPLATE).tmpl" "templates/cloud-init.tmpl"
	@if [ -f "template-examples/.env.$(TEMPLATE).example" ]; then \
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

# Render template from environment variables using gomplate
render-template:
	@echo "Rendering template with gomplate..."
	@if [ ! -f ".env" ]; then \
		echo "Error: .env file not found. Please copy a template .env file and configure it."; \
		echo "Run 'make copy-template TEMPLATE=<template-name>' first."; \
		exit 1; \
	fi
	@if ! command -v gomplate >/dev/null 2>&1; then \
		echo "Error: gomplate is required for template rendering."; \
		echo "Run 'make install-gomplate' to install it."; \
		exit 1; \
	fi
	@echo "Rendering templates/cloud-init.tmpl to templates/cloud-init.yaml..."
	@gomplate -f templates/cloud-init.tmpl -d env=.env > templates/cloud-init.yaml
	@echo "✅ Template rendered successfully: templates/cloud-init.yaml"

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
	@echo "  make list-templates           # List available templates"
	@echo "  make copy-template            # Copy a template to use"
	@echo "  make render-template          # Render current template"
	@echo "  make create-base-image        # Create VM from current template"
	@echo ""
	@echo "VM Management:"
	@echo "  make list-vms                 # List all VMs"
	@echo "  make stop-all-vms             # Stop all VMs"
	@echo "  make delete-all-vms           # Delete and purge all VMs"
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

# ==============================================================================
# Kestra Flow Management
# ==============================================================================

KESTRA_NAMESPACE ?= dev.orch
CONTAINER_CMD ?= $(shell command -v podman || command -v docker)
KESTRA_CONTAINER_NAME = kestra
KESTRA_SERVER_URL = http://localhost:8080

.PHONY: kestra-help kestra-validate kestra-deploy

kestra-help:
	@echo "Kestra Flow Management Commands"
	@echo ""
	@echo "Usage:"
	@echo "  make kestra-validate"
	@echo "  make kestra-deploy [KESTRA_NAMESPACE=my.namespace]"
	@echo ""
	@echo "Description:"
	@echo "  These commands use the Kestra CLI running inside the Docker container to manage your flows."
	@echo "  They require KESTRA_USER and KESTRA_PASSWORD to be set in your environment."
	@echo ""
	@echo "Prerequisites:"
	@echo "  1. The Kestra Docker containers must be running ('podman-compose up -d')."
	@echo "  2. You must have the user and password for the Kestra instance."
	@echo "     - The default credentials in 'kestra.yml' are kestra:password."
	@echo "     - For security, add these to a local .env file (already in .gitignore):"
	@echo "         KESTRA_USER=kestra"
	@echo "         KESTRA_PASSWORD=password"
	@echo "     - Then, load the variables into your shell:"
	@echo "         source .env"
	@echo ""
	@echo "Variables:"
	@echo "  KESTRA_NAMESPACE  - The namespace to deploy flows to (default: $(KESTRA_NAMESPACE))"
	@echo "  CONTAINER_CMD     - The container command to use (podman or docker, default: $(CONTAINER_CMD))"

kestra-validate:
	@echo "--- Kestra Validation Debug ---"
	@echo "Checking environment variables..."
	@if [ -z "$(KESTRA_USER)" ] || [ -z "$(KESTRA_PASSWORD)" ] || [ -z "$(KESTRA_SERVER_URL)" ] || [ -z "$(CONTAINER_CMD)" ] || [ -z "$(KESTRA_CONTAINER_NAME)" ]; then \
		echo "❌ Error: One or more required environment variables are not set."; \
		echo "   KESTRA_USER: $(KESTRA_USER)"; \
		echo "   KESTRA_PASSWORD: $(if $(KESTRA_PASSWORD),set,not set)"; \
		echo "   KESTRA_SERVER_URL: $(KESTRA_SERVER_URL)"; \
		echo "   CONTAINER_CMD: $(CONTAINER_CMD)"; \
		echo "   KESTRA_CONTAINER_NAME: $(KESTRA_CONTAINER_NAME)"; \
		make kestra-help; \
		exit 1; \
	else \
		echo "✅ All required environment variables are set."; \
	fi
	@echo "KESTRA_SERVER_URL: $(KESTRA_SERVER_URL)"
	@echo "CONTAINER_CMD: $(CONTAINER_CMD)"
	@echo "KESTRA_CONTAINER_NAME: $(KESTRA_CONTAINER_NAME)"
	@echo "---------------------------------"
	@echo ""
	@echo "Validating all flows in ./kestra-flows..."
	@find ./kestra-flows -name '*.yaml' -o -name '*.yml' | while read flow_file; do \
		container_flow_path=$$(echo "$$flow_file" | sed 's|^\./kestra-flows|/app/flows|'); \
		echo "--> Validating $$container_flow_path in container..."; \
		CMD_TO_RUN="/app/kestra flow validate \"$$container_flow_path\" --server \"$(KESTRA_SERVER_URL)\" --user \"$(KESTRA_USER):$(KESTRA_PASSWORD)\""; \
		$(CONTAINER_CMD) exec $(KESTRA_CONTAINER_NAME) sh -c "$$CMD_TO_RUN"; \
	done
	@echo "✅ All flows validated successfully."

kestra-deploy:
	@if [ -z "$(KESTRA_USER)" ] || [ -z "$(KESTRA_PASSWORD)" ] || [ -z "$(KESTRA_SERVER_URL)" ] || [ -z "$(CONTAINER_CMD)" ] || [ -z "$(KESTRA_CONTAINER_NAME)" ]; then \
		echo "❌ Error: One or more required Kestra environment variables are not set."; \
		echo "   KESTRA_USER: $(KESTRA_USER)"; \
		echo "   KESTRA_PASSWORD: $(if $(KESTRA_PASSWORD),set,not set)"; \
		echo "   KESTRA_SERVER_URL: $(KESTRA_SERVER_URL)"; \
		echo "   CONTAINER_CMD: $(CONTAINER_CMD)"; \
		echo "   KESTRA_CONTAINER_NAME: $(KESTRA_CONTAINER_NAME)"; \
		make kestra-help; \
		exit 1; \
	fi
	@echo "Deploying all flows from /app/flows to namespace '$(KESTRA_NAMESPACE)'..."
	CMD_TO_RUN="/app/kestra flow namespace update $(KESTRA_NAMESPACE) /app/flows --no-delete --server $(KESTRA_SERVER_URL) --user '$(KESTRA_USER):$(KESTRA_PASSWORD)'"; \
	$(CONTAINER_CMD) exec $(KESTRA_CONTAINER_NAME) sh -c "$$CMD_TO_RUN";
	@echo "✅ Deployment complete."
