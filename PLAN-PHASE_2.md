# Plan for Phase 2: VM Lifecycle Management with Multipass

This document outlines the detailed plan for implementing the Kestra workflow to manage the lifecycle of Multipass VMs as described in Phase 2 of `TASKS.md`.

## 1. Objective

The primary goal is to create a robust Kestra flow that automates the creation, use, and destruction of a Multipass Virtual Machine on a remote server. This flow will serve as the foundation for running analysis workloads in isolated, clean environments.

## 2. Kestra Flow Design

The flow will be designed to be stateless and idempotent. Each execution will manage a single, unique VM from launch to deletion, ensuring no conflicts between concurrent runs.

### Flow Details

-   **ID:** `multipass-vm-lifecycle`
-   **Namespace:** `dev.orch`
-   **Description:** A flow to launch a Multipass VM from a base image, execute a command, and then destroy the VM.

### Inputs

The flow will require the following inputs to be provided at runtime:

-   `base_image_name` (string, required): The name of the Multipass golden image to launch (e.g., `ubuntu-lts-agent`).
-   `workload_command` (string, required): The command to be executed inside the newly created VM.
-   `debug_mode` (boolean, optional, default: false): If true, the VM will not be cleaned up after execution.
-   `vm_cpus` (integer, optional, default: 1): The number of CPUs to allocate to the VM.
-   `vm_memory` (string, optional, default: "1G"): The amount of memory to allocate (e.g., "512M", "2G").
-   `vm_disk` (string, optional, default: "5G"): The amount of disk space to allocate.

### Secrets

The flow will rely on Kestra's secret management for secure access to the Multipass host.

-   `MULTIPASS_HOST`: The hostname or IP address of the server where Multipass is running.
-   `MULTIPASS_SSH_USER`: The username for SSH access to the Multipass host.
-   `MULTIPASS_SSH_PRIVATE_KEY`: The private SSH key for passwordless authentication to the Multipass host.

### Task Breakdown

The core logic will be implemented as a sequence of tasks. A key feature will be the use of an `ALL_ALWAYS` task to ensure cleanup happens regardless of success or failure.

1.  **`generate_vm_name` (Shell Task):**
    -   **Purpose:** Create a unique name for the VM for this specific flow execution. This is critical for preventing collisions during concurrent runs.
    -   **Implementation:** Use a combination of the flow's ID and Kestra's unique execution ID variable.
    -   **Example Script:** `echo "vm_name=kestra-{{ execution.id | slug }}"`
    -   **Output:** The generated VM name will be passed to subsequent tasks.

2.  **`launch_vm` (SSH Command Task):**
    -   **Purpose:** Connect to the Multipass host and launch a new VM instance.
    -   **Connection:** Uses the secrets for host, user, and private key.
    -   **Command:** `multipass launch {{ inputs.base_image_name }} --name {{ outputs.generate_vm_name.vars.vm_name }} --cpus {{ inputs.vm_cpus }} --mem {{ inputs.vm_memory }} --disk {{ inputs.vm_disk }}`

3.  **`execute_workload` (SSH Command Task):**
    -   **Purpose:** Execute the user-provided command inside the newly created VM.
    -   **Command:** `multipass exec {{ outputs.generate_vm_name.vars.vm_name }} -- {{ inputs.workload_command }}`
    -   **Note:** This task is where the main analysis process (from Phase 3) will eventually be triggered.

4.  **`cleanup_vm` (Conditional, ALL_ALWAYS Task Group):**
    -   **Purpose:** This task group will run if `debug_mode` is `false`. It will **always** run on failure or success to ensure the VM is stopped and deleted. This prevents orphaned VMs in normal runs.
    -   **Condition:** `{{ inputs.debug_mode == false }}`
    -   **Tasks within the group:**
        -   **`stop_vm` (SSH Command):** `multipass stop {{ outputs.generate_vm_name.vars.vm_name }}`
        -   **`delete_vm` (SSH Command):** `multipass delete {{ outputs.generate_vm_name.vars.vm_name }} --purge`

## 3. Implementation Details

### Remote Execution via SSH

-   All `multipass` commands will be executed on the remote host using Kestra's built-in `io.kestra.plugin.fs.ssh.Command` task.
-   This approach centralizes control within Kestra and requires no Kestra agent on the Multipass host itself.

### Concurrency and State

-   By generating a unique VM name for each execution (`kestra-{{ execution.id }}`), we guarantee that multiple instances of this flow can run in parallel without interfering with each other.
-   The flow is entirely self-contained. It creates all necessary resources and cleans them up upon completion. No state is maintained between executions.

### Error Handling

-   The primary error handling mechanism is the `ALL_ALWAYS` (or `errors`) task group for cleanup. If `debug_mode` is false, this group runs unconditionally upon success or failure. If any task in the main sequence fails (e.g., the workload script returns a non-zero exit code), Kestra will immediately proceed to the cleanup tasks.
-   The cleanup commands themselves should be idempotent. For example, running `multipass delete` on a non-existent machine may fail, which should be configured to not fail the entire flow. We can append `|| true` to the commands to ensure they don't fail the cleanup step if the VM is already gone.

## 4. Prerequisites

Before development begins, the following infrastructure and configuration must be in place:

1.  **Multipass Host:** A server (Linux or macOS) with Multipass installed and running.
2.  **SSH Access:** An SSH user account must be created on the Multipass host for Kestra.
3.  **SSH Keys:** An SSH key pair must be generated. The public key should be added to the `~/.ssh/authorized_keys` file for the Kestra user on the Multipass host to allow passwordless login.
4.  **Kestra Secrets:** The Multipass host, SSH user, and the private SSH key must be securely stored as secrets within the Kestra instance.
5.  **Base Image:** The specified golden/base image must be available in Multipass on the host machine.

## 5. Action Plan

1.  **Setup Prerequisites:** Configure the Multipass host, user, and SSH keys.
2.  **Store Secrets in Kestra:** Add `MULTIPASS_HOST`, `MULTIPASS_SSH_USER`, and `MULTIPASS_SSH_PRIVATE_KEY` to the Kestra secret backend.
3.  **Develop Kestra Flow:** Create a new YAML file `kestra-flows/multipass-vm-lifecycle.yaml`.
4.  **Implement Tasks:**
    -   Define the inputs as specified above.
    -   Create the `generate_vm_name` task.
    -   Create the `launch_vm` task, referencing the inputs and secrets.
    -   Create the `execute_workload` task as a placeholder.
    -   Create the `cleanup_vm` tasks and configure them to run always.
5.  **Initial Testing:**
    -   Run the flow with a simple workload command like `ls -l /`.
    -   Verify that the VM is created on the Multipass host, the command executes, and the VM is subsequently deleted.
6.  **Failure Testing:**
    -   Run the flow with a failing workload command like `exit 1`.
    -   Verify that the `execute_workload` task fails but the `cleanup_vm` tasks still run successfully, leaving no orphaned VM.
7.  **Debug Mode Testing:**
    -   Run the flow with `debug_mode` set to `true`.
    -   Verify that the VM is created and the workload runs, but the VM is *not* deleted upon completion.
    -   Manually clean up the VM on the Multipass host after verification.