### **Project Description**

This project will create an automated system for orchestrating Virtual Machines (VMs) to run analysis workloads. The system will use **Kestra** to manage the entire lifecycle of the VMs, from creation to cleanup, using **Canonical's Multipass** for local VM management. This allows the entire pipeline to be developed and run on a local machine (macOS or Linux).

Each VM will be created from a pre-configured golden image. Kestra will then use the VM to run a specific analysis process, triggered by a string prompt, before destroying the VM to ensure a clean and repeatable environment for each task.

### **Project Phases**

**Phase 1: Proof of Concept**

*   **Objective:** Validate Kestra as a viable orchestration tool for the project's core requirements.
*   **Tasks:**
    *   Install and configure a local Kestra instance.
    *   Set up a simple Kestra flow that accepts a string input.
    *   The flow should log the input to demonstrate basic queueing and parameter passing.
    *   Verify the system's basic functionality.

**Phase 2: VM Lifecycle Management with Multipass**

*   **Objective:** Automate the creation, setup, and destruction of VMs using Multipass.
*   **Tasks:**
    *   Develop Kestra flows that use the `multipass launch` command to create a new VM instance from the golden image snapshot.
    *   Implement tasks that use `multipass exec` or direct SSH to run commands inside the newly created VM.
    *   Create a Kestra flow to gracefully stop and delete the VM instance using `multipass stop` and `multipass delete`.
    *   Implement robust error handling to ensure VMs are destroyed even if a step in the process fails.
    *   **Investigate and implement a secure method for Kestra to handle SSH keys** required for connecting to the Multipass VMs.

**Phase 3: Workload Execution and Parameterization**

*   **Objective:** Execute the main analysis process within the VM and pass dynamic parameters to it.
*   **Tasks:**
    *   Enhance the Kestra flow to execute the pre-installed analysis agent (e.g., Claude Code CLI, Gemini CLI, or Crush) via an SSH or `multipass exec` command.
    *   Implement the mechanism to pass the input string from the Kestra flow as a prompt to the analysis agent.
    *   Define a preliminary method to capture the output (stdout) from the agent process.
    *   Store or log the results of the analysis for review.

**Phase 4: Integration and Automation**

*   **Objective:** Integrate the system with external triggers and add monitoring capabilities.
*   **Tasks:**
    *   Set up webhook triggers in Kestra to allow for on-demand execution of the VM orchestration pipeline.
    *   Configure scheduled and recurring analysis tasks if needed.
    *   Implement basic monitoring and alerting for flow failures.
    *   Add controls for managing concurrent VM instances to avoid overwhelming the local machine.

### **Technical Specifications & Decisions**

*   **VM Orchestration:** Canonical's Multipass (CLI-based).
*   **Environment:** Local-first development and execution (macOS / Linux). Multipass's remote capabilities can be leveraged later for scaling.
*   **Base VM Image:** A pre-configured golden image with the analysis agent and its dependencies is assumed to be available.
*   **Analysis Process:** An agent on the VM (e.g., Claude Code CLI, Gemini CLI, or Crush) will be executed.
*   **Primary Input:** A single string which serves as the prompt for the analysis agent.

### **Key Decisions & Open Investigations**

**1. Security and Access:**
*   **SSH Key Management (High Priority):** How will SSH keys be stored, accessed, and used by Kestra flows securely? Options include Kestra's secret management, environment variables, or volume mounts if using Docker.

**2. Analysis Process Details:**
*   **Output Handling:** What is the expected output from the analysis agent (e.g., files, JSON to stdout)? How should this output be captured and stored for downstream use?

**3. Kestra Configuration:**
*   **Kestra Hosting:** For the POC, Kestra will run locally (e.g., via Docker). Long-term hosting needs to be decided.
*   **Resource Management:** How will Kestra's own resource consumption be managed, especially when orchestrating multiple concurrent VMs?

**4. Error Handling and Recovery:**
*   **Multipass Failures:** What are the specific failure modes of Multipass (e.g., launch failure, network issues) and how should the Kestra flow react?
*   **Retry Logic:** What is the desired retry logic for failed tasks (e.g., retry VM creation once)?

**5. Networking:**
*   **Local Network:** For now, all operations are local, so complex network security (firewalls, VPCs) is not applicable. This may become relevant if/when using Multipass's remote features.
