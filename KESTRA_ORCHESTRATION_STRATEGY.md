# Kestra Orchestration and Queuing Strategy

This document outlines the architectural approach for processing a list of VM-based analysis tasks using Kestra. It clarifies Kestra's role in the system and defines the division of responsibilities between Kestra and any external queuing or dispatching mechanism.

## Understanding Kestra's Role: Orchestrator vs. Queue

It is critical to understand that Kestra is a **workflow orchestrator**, not a persistent message queue.

*   **As an orchestrator**, Kestra excels at executing a defined sequence of tasks with complex dependencies, error handling, and retry logic. Its purpose is to manage the *process* of getting a single job done reliably.
*   **It is not a message queue** like RabbitMQ, AWS SQS, or Kafka. These systems are designed for long-term storage and distribution of messages (tasks). Kestra is not designed to be the primary, persistent "source of truth" for a list of pending jobs.

With this distinction in mind, there are two primary patterns for orchestrating a list of tasks with Kestra.

---

## Pattern 1: External Trigger per Task (Recommended for POC)

In this model, an external system maintains the master list of tasks and triggers a Kestra workflow for each individual task.

### How It Works

1.  A persistent data store (like a database, a file, or a message queue) holds the master list of all analysis jobs to be completed.
2.  An external "dispatcher" process reads one job from the list.
3.  The dispatcher makes a single webhook call to a Kestra flow's trigger endpoint, passing the parameters for that one job (e.g., `git_branch`, `input_file`) in the webhook payload.
4.  Kestra creates a **new, independent "Flow Run"** for that single job and executes the full VM lifecycle.
5.  The dispatcher can continue sending triggers for other jobs. Kestra's internal executor will queue these flow runs and execute them as worker capacity allows, providing natural concurrency control and backpressure.

### Division of Labor

*   **Kestra's Role**:
    *   Execute the end-to-end lifecycle for **one** VM analysis task.
    *   Manage the complex inner dependencies of that single task (create VM -> SSH -> run script -> destroy VM).
    *   Handle retries and error conditions for a single task.
    *   Control concurrency of executing tasks via its worker configuration.
*   **External System's Role**:
    *   Maintain the persistent, long-term queue of all tasks.
    *   Implement any priority logic (e.g., query the database for high-priority jobs first).
    *   Dispatch individual job triggers to Kestra.

---

## Pattern 2: Internal Fan-Out with `EachParallel` (Advanced)

In this model, an entire batch of tasks is sent to Kestra at once, and Kestra internally "fans out" the work.

### How It Works

1.  An external system gathers a list of jobs and sends a **single webhook trigger** to a "master" Kestra flow. The payload is a JSON array containing all the jobs.
2.  The first task in this master flow is a Kestra `EachParallel` (or `EachSequential`) task.
3.  This task iterates over the input array. For each item, it executes a "sub-flow" (a separate, reusable workflow), passing the item's data as input.
4.  Kestra executes all these sub-flows in parallel (up to a configurable limit), with each sub-flow managing the lifecycle of a single VM.

### Division of Labor

*   **Kestra's Role**:
    *   Receives the entire batch of work.
    *   Manages the top-level "master" flow run.
    *   Dynamically creates and orchestrates all the child flows based on the input list.
    *   Provides a single point of monitoring for the entire batch.
*   **External System's Role**:
    *   Bundles up the list of tasks and sends it in a single trigger.

---

## Summary: Division of Responsibilities

| Responsibility | Kestra Handles | External System Handles |
| :--- | :--- | :--- |
| **Executing a Single Job** | ✅ **Yes.** This is its core strength. | ❌ **No.** |
| **Managing Dependencies within a Job**| ✅ **Yes.** (e.g., `run_script` depends on `create_vm`) | ❌ **No.** |
| **Error Handling & Retries for a Job**| ✅ **Yes.** (e.g., retry a failed VM creation) | ❌ **No.** |
| **Maintaining a Persistent Queue** | ❌ **No.** Kestra is not a database or message broker. | ✅ **Yes.** Use a proper database or message queue for this. |
| **Complex Queuing Logic (Priority)** | ❌ **No.** Kestra's internal queue is typically FIFO. | ✅ **Yes.** The external system decides what to send next. |
| **Fanning Out a List of Tasks** | ✅ **Yes.** Using the `EachParallel` task. | ✅ **Yes.** By sending individual triggers. |

## Conclusion and POC Strategy

For the Proof of Concept, we will use **Pattern 1: External Trigger per Task**.

This approach provides the clearest separation of concerns and allows the team to focus on the most complex and critical part of the project: **building a robust and reliable Kestra flow for the end-to-end lifecycle of a single VM.**

By starting with this pattern, we can perfect the core logic of VM creation, setup, execution, and cleanup without adding the complexity of batch management. The "external dispatcher" can be simulated with a simple `curl` command or a basic script during development. Once the single-job flow is proven, we can easily integrate it with any external queuing system.