#!/bin/bash

# This script triggers the 'multipass-vm-lifecycle' Kestra flow.
# It sources environment variables from a .env file located in the project root.

set -e


# Get the directory of the script to reliably locate the .env file
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT_DIR=$(dirname "$SCRIPT_DIR")
ENV_FILE="$PROJECT_ROOT_DIR/.env"

# Check if .env file exists and source it
if [ -f "$ENV_FILE" ]; then
    echo "Sourcing environment variables from $ENV_FILE"
    # Use 'set -a' to export all variables created in the .env file
    set -a
    source "$ENV_FILE"
    set +a

else
    echo "Error: .env file not found at $ENV_FILE"
    echo "Please create a .env file with KESTRA_SERVER_URL, KESTRA_USER, KESTRA_PASSWORD, and KESTRA_NAMESPACE."
    exit 1
fi

# Check for required environment variables

if [ -z "$KESTRA_SERVER_URL" ] || [ -z "$KESTRA_USER" ] || [ -z "$KESTRA_PASSWORD" ] || [ -z "$KESTRA_NAMESPACE" ]; then
    echo "Error: KESTRA_SERVER_URL, KESTRA_USER, KESTRA_PASSWORD, and KESTRA_NAMESPACE must be set in the .env file."
    exit 1
fi
# Define flow details
FLOW_ID="multipass-vm-lifecycle"
KESTRA_EXECUTION_URL="${KESTRA_SERVER_URL}/api/v1/executions/${KESTRA_NAMESPACE}/${FLOW_ID}"

# Input parameters
BASE_IMAGE_NAME="python-template"
WORKLOAD_COMMAND="ls -la"
DEBUG_MODE=false
VM_CPUS=2
VM_MEMORY="8G"
VM_DISK="80G"

echo "Triggering Kestra flow '${KESTRA_NAMESPACE}.${FLOW_ID}'..."
echo "URL: $KESTRA_EXECUTION_URL"

# Execute the curl command to trigger the flow
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  --user "$KESTRA_USER:$KESTRA_PASSWORD" \
  -H "Content-Type: multipart/form-data" \
  -F "base_image_name=$BASE_IMAGE_NAME" \
  -F "workload_command=$WORKLOAD_COMMAND" \
  -F "debug_mode=$DEBUG_MODE" \
  -F "vm_cpus=$VM_CPUS" \
  -F "vm_memory=$VM_MEMORY" \
  -F "vm_disk=$VM_DISK" \
  "${KESTRA_EXECUTION_URL}")

# Extract the body and HTTP status code
HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

echo ""
echo "---"
echo "Response (HTTP Status: $HTTP_STATUS):"
# Pretty print JSON if jq is available
if command -v jq &> /dev/null; then
    echo "$HTTP_BODY" | jq .
else
    echo "$HTTP_BODY"
fi

if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "Error: Kestra API returned a non-200 status code."
  exit 1
fi

echo "---"
EXECUTION_ID=$(echo "$HTTP_BODY" | jq -r '.id')
if [ -n "$EXECUTION_ID" ] && [ "$EXECUTION_ID" != "null" ]; then
    echo "Flow execution started successfully!"
    echo "View execution at: ${KESTRA_SERVER_URL}/ui/executions/${KESTRA_NAMESPACE}/${FLOW_ID}/${EXECUTION_ID}"
else
    echo "Could not determine execution ID from the response."
fi
