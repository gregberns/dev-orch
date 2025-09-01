

## Objective

A pool of VMs, all being the same base image, will be used to run workloads that are orchestrated somehow. When a new task is added to the queue,

* Create a VM instance from a snapshot
* Start the VM
* In the vm (probably best via SSH)
  * Run a set of scripts that will set up the environment (git pull, etc)
  * Run a process with specific input parameters. THIS IS THE KEY PART OF THE PROCESS.
* Once complete, cleanup the vm and get it ready for another use.



## Phase 1

We should start with a very basic setup to make sure Kestra is the right tool to use.

* Configure Kestra
* Setup a queue mechanism in Kestra that can process a list of requests. Each request being a couple string inputs, and the Kestra process just logs the inputs.
* Test the system works



## Details Part 1

This project creates an automated VM orchestration system that:

1. **Creates ephemeral VMs** from golden image snapshots on demand
2. **Automates environment setup** by running predefined scripts inside the VM (git operations, dependency installation, etc.)
3. **Executes analysis processes** with dynamic input parameters
4. **Cleans up resources** automatically after completion, destroying the VM and making it ready for the next use

The system provides a repeatable, self-contained environment for running analysis tasks without manual intervention, ensuring consistent setup and automatic resource management.

## Details Part 2

Based on the documentation, here are the critical details for this VM orchestration system:

## VM Creation & Configuration
- **Source**: Uses golden image snapshots (e.g., "python-template") as base images
- **Naming**: Unique VM names with tracking and management capabilities
- **Network**: SSH access with key-based authentication

## Environment Setup Scripts
- **Git Operations**: Clone/pull repositories, branch management, working directory setup
- **Dependency Installation**: Install Claude Code CLI and required analysis tools
- **Configuration**: Environment setup and working directory preparation
- **Error Handling**: Automated recovery and cleanup for setup failures

## Analysis Process Execution
- **Claude Code CLI**: Headless execution of AI-assisted code analysis
- **Dynamic Parameters**: Inject analysis prompts and configurations from workflow inputs
- **Output Processing**: Capture and parse analysis results for downstream use
- **Multiple Analysis Types**: Support for different analysis scenarios and prompts

## Resource Management
- **Lifecycle Control**: Complete VM lifecycle (create → setup → analyze → cleanup)
- **Health Monitoring**: Continuous VM health checking and automated recovery
- **Resource Limits**: Configurable concurrent VM limits and resource monitoring
- **Cleanup Guarantee**: 100% resource cleanup even on workflow failures

## Integration & Automation
- **Event-Driven**: Webhook triggers for on-demand execution
- **Scheduling**: Support for scheduled and recurring analysis tasks
- **Error Recovery**: Comprehensive retry logic and error handling
- **Monitoring**: Full execution tracking and performance metrics

The system transforms manual VM management into a fully automated pipeline that can handle multiple concurrent analysis tasks with consistent, repeatable results and guaranteed resource cleanup.
