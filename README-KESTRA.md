# Kestra Orchestration Setup

This document describes the Kestra orchestration setup that has been integrated into the dev-orch-n8n project as an alternative to n8n.

## Overview

Kestra is an open-source, event-driven orchestration platform that simplifies scheduled and event-driven workflows using Infrastructure as Code principles and a declarative YAML interface. It has been added to complement the existing n8n setup and provide a more robust orchestration solution.

## Architecture

### Services
The Docker Compose setup includes:
- **Kestra**: Main orchestration service (port 8080 for UI/API, 8081 for internal API)
- **PostgreSQL**: Database for both n8n and Kestra (shared for simplicity)
- **n8n**: Legacy orchestration service (still available)
- **Sidecar API**: For multipass VM management (legacy n8n integration)

### Kestra Configuration
- **Storage**: Local filesystem storage in `/app/data`
- **Queue**: PostgreSQL for task queuing
- **Executor**: Embedded executor with thread pool
- **Worker**: Embedded worker with thread pool

## Quick Start

### 1. Start the Services
```bash
# Start all services including Kestra
docker-compose up -d

# Or start only Kestra and its dependencies
docker-compose up -d postgres kestra
```

### 2. Access Kestra UI
Open your browser and navigate to: `http://localhost:8080`

### 3. Load Workflows
Run the deployment script to load the predefined workflows:
```bash
./scripts/load-kestra-flows.sh
```

## Workflows

### 1. Hello World (`hello-world.yaml`)
- **Namespace**: `default`
- **Description**: Simple greeting workflow to test Kestra functionality
- **Features**: 
  - Input parameters
  - Logging tasks
  - Error handling
  - Manual trigger via webhook

### 2. Environment Orchestration (`environment-orchestration.yaml`)
- **Namespace**: `devops`
- **Description**: Workflow for managing environments (start/stop/status)
- **Features**:
  - Input validation
  - Conditional execution (Switch task)
  - Simulation of environment operations
  - Error handling and retry logic

### 3. Data Processing (`data-processing.yaml`)
- **Namespace**: `analytics`
- **Description**: End-to-end data processing pipeline
- **Features**:
  - Data download from external source
  - Data validation with pandas
  - Multiple output formats (JSON, CSV, Parquet)
  - Automated reporting
  - Scheduled execution (every 6 hours)
  - Comprehensive error handling and retry logic

## Workflow Management

### Manual Execution
1. Go to Kestra UI: `http://localhost:8080`
2. Navigate to the desired flow
3. Click "Create Execution"
4. Fill in any required inputs
5. Click "Run"

### Scheduled Execution
- The `data-processing` workflow is scheduled to run every 6 hours
- Schedule can be modified in the workflow YAML or via the Kestra UI

### Webhook Triggers
- `hello-world`: Trigger at `/api/v1/executions/hello-world-trigger`
- `environment-orchestration`: Trigger at `/api/v1/executions/environment-orchestration-trigger`

## CLI Usage

### Install Kestra CLI
```bash
# The deployment script will install it automatically, or manually:
# For macOS
curl -Ls https://github.com/kestra-io/kestra/releases/latest/download/kestra-darwin-amd64 -o kestra
chmod +x kestra
sudo mv kestra /usr/local/bin/

# For Linux
curl -Ls https://github.com/kestra-io/kestra/releases/latest/download/kestra-linux-amd64 -o kestra
chmod +x kestra
sudo mv kestra /usr/local/bin/
```

### Configure CLI
```bash
kestra config server set http://localhost:8080
kestra config auth token --create
```

### Common Commands
```bash
# List flows
kestra flow list

# Trigger execution
kestra execution trigger hello-world

# Get execution status
kestra execution get <execution-id>

# View execution logs
kestra execution logs <execution-id>

# Deploy a new flow
kestra flow create --file ./kestra-flows/new-flow.yaml
```

## Development

### Adding New Workflows
1. Create a new YAML file in the `kestra-flows/` directory
2. Follow the Kestra workflow schema
3. Test the workflow using the Kestra UI
4. Deploy using the CLI or the deployment script

### Workflow Structure
```yaml
id: my-workflow
namespace: my-team
description: "Description of the workflow"

inputs:
  - id: param1
    type: STRING
    description: "Parameter description"

tasks:
  - id: task1
    type: io.kestra.plugin.core.log.Log
    message: "Hello, {{ inputs.param1 }}!"

triggers:
  - id: manual
    type: io.kestra.plugin.core.trigger.Webhook
    key: my-workflow-trigger

errors:
  - id: handle-error
    type: io.kestra.plugin.core.log.Log
    message: "Error: {{ execution.errorMessage }}"
```

### Available Plugins
Kestra comes with many built-in plugins:
- **Core**: Logging, scripting, HTTP requests, file operations
- **Database**: PostgreSQL, MySQL, SQLite, Snowflake
- **Scripting**: Python, Shell, Docker commands
- **Git**: Clone, push, sync operations
- **Cloud**: AWS, GCP, Azure integrations
- **Data Processing**: dbt, Airflow, Spark integrations

## Configuration

### Environment Variables
- `KESTRA_CONFIGURATION_URL`: Path to configuration file
- Database connection details are inherited from the shared PostgreSQL service

### Configuration File
The `kestra-config/standalone.yml` file contains:
- Server settings
- Storage configuration
- Queue settings
- Plugin configuration
- Security settings (basic auth available)
- Logging levels

### Data Persistence
- Flow definitions: Stored in PostgreSQL
- Execution data: Stored in `/app/data` on the host
- Configuration: `/kestra-config` directory

## Monitoring and Logging

### Kestra UI
- **Dashboard**: Overview of executions and flows
- **Executions**: View running and completed executions
- **Flows**: Manage and monitor workflow definitions
- **Logs**: Real-time and historical logs

### Execution History
All executions are stored and can be:
- Viewed in the UI
- Filtered by status, date, flow
- Exported for analysis

### Error Handling
- Automatic retry with configurable policies
- Error handlers for specific failure scenarios
- Detailed error messages and stack traces

## Migration from n8n

### Key Differences
- **Declarative YAML** vs Visual editor
- **Event-driven** vs Scheduled-based
- **Plugin architecture** vs Node-based
- **GitOps-friendly** vs UI-based management

### Migration Strategy
1. Start by running both orchestrators in parallel
2. Port simple workflows first
3. Gradually migrate complex workflows
4. Use Kestra's webhook triggers for event-based workflows
5. Leverage Kestra's scheduling for periodic tasks

### Benefits of Kestra
- **Infrastructure as Code**: Workflows are version-controlled
- **Scalability**: Built-in distributed execution
- **Extensibility**: Rich plugin ecosystem
- **Monitoring**: Comprehensive execution tracking
- **Cost-effective**: Open-source with enterprise support options

## Troubleshooting

### Common Issues

**Kestra not starting**
```bash
# Check logs
docker-compose logs kestra

# Verify PostgreSQL is running
docker-compose ps postgres

# Check port conflicts
lsof -i :8080
```

**Workflows not deploying**
```bash
# Validate flow syntax
kestra flow validate --file ./kestra-flows/your-flow.yaml

# Check Kestra connection
curl http://localhost:8080/api/v1/health
```

**Execution failures**
- Check task logs in the Kestra UI
- Verify input parameters
- Check resource availability (disk space, network)
- Review error handlers in workflow definitions

### Health Checks
```bash
# Kestra health check
curl http://localhost:8080/api/v1/health

# PostgreSQL health check
docker-compose exec postgres pg_isready -U n8n -d n8n
```

## Next Steps

1. **Explore the UI**: Navigate through the Kestra interface to understand the workflow management
2. **Create Custom Workflows**: Start building your own orchestration workflows
3. **Integrate with Existing Systems**: Connect Kestra to your databases, APIs, and services
4. **Set up CI/CD**: Automate workflow deployment using GitHub Actions or similar
5. **Monitor Performance**: Use Kestra's built-in monitoring and set up alerts

## Resources

- [Kestra Documentation](https://kestra.io/docs/)
- [Kestra GitHub](https://github.com/kestra-io/kestra)
- [Plugin Registry](https://kestra.io/plugins/)
- [Community Discord](https://kestra.io/discord/)

For questions or issues, refer to the troubleshooting section or check the Kestra documentation.