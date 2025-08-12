#!/usr/bin/env bash

set -e # Exit immediately if a command exits with a non-zero status.

# Define the repository and the target directory
REPO_URL="git@github.com:SidegigLLC/sidegig-api.git"
CLONE_DIR="sidegig-api"

# --- Main Script ---

# Navigate to the workspace directory
# Check if workspace directory exists, if not, create it.
if [ ! -d "workspace" ]; then
    echo "Creating workspace directory..."
    mkdir -p workspace
fi
cd workspace

# Check if the repository directory already exists
if [ -d "$CLONE_DIR" ]; then
    echo "Repository '$CLONE_DIR' already exists. Skipping clone."
else
    echo "Cloning repository '$REPO_URL'..."
    # Disable host key checking for this command only
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone "$REPO_URL"
fi

# Navigate into the repository's devcontainer directory
cd "$CLONE_DIR/.devcontainer"

# Pull the container image(s)
# This command is naturally idempotent.
echo "Pulling container images for 'db' service..."
podman-compose pull db

# Navigate back to the project root
cd ..

pip install -r requirements.txt

cp ~/dev/sidegig-api/.env .env

echo "Setup complete."
