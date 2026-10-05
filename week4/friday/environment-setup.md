# KijaniKiosk Week 4 Friday Environment Setup

## Host Environment

The Friday Infrastructure as Code pipeline was developed and tested on the following host environment:

- Operating system: Ubuntu 26.04.1 LTS
- Terraform: 1.16.4
- Multipass: 1.16.4
- Ansible Core: 2.20.1
- Docker: 29.8.1
- MinIO: DEVELOPMENT.2026-07-17T10-40-15Z
- MinIO commit: 3cd981e1616a18c5679805bf9a1454d794bbee4f

## Target Servers

The KijaniKiosk application infrastructure uses three Ubuntu 22.04.5 LTS Multipass virtual machines:

- API server: kijanikiosk-api
- Payments server: kijanikiosk-payments
- Logs server: kijanikiosk-logs

The VM addresses are discovered dynamically during Terraform execution rather than being permanently hardcoded into the Terraform configuration.

## Terraform Configuration

Terraform uses a reusable app_server module and creates the three application server resources with `for_each`. Environment, region, instance type, SSH key name, SSH user, and private-key path are represented as Terraform variables.

Terraform state is stored remotely using the local MinIO S3-compatible service. The configured state object is stored in the KijaniKiosk Terraform state bucket under the staging state key.

The local MinIO backend provides persistent remote state for the development environment. MinIO's S3-compatible backend does not provide native Terraform state locking in this configuration. This limitation is documented in the hardening decisions and would need to be addressed in production using a backend that provides supported locking, such as an appropriate cloud backend or Consul.

## Ansible Configuration

Ansible configures all three servers using a shared playbook, group variables, host variables, and Jinja2 templates.

The configuration establishes:

- Required operating-system packages
- KijaniKiosk service accounts and groups
- Application directory structure
- Service-specific systemd units
- UFW firewall policy
- Persistent systemd journal storage
- Log rotation
- Shared logging permissions
- Service-specific configuration
- Systemd service hardening

The SSH private-key path is represented as an Ansible group variable so that the inventory does not contain a fixed private-key path.

## Pipeline Execution

The `pipeline.sh` script performs the complete deployment workflow. It runs Terraform plan and apply, extracts the dynamically discovered server addresses, generates the Ansible inventory, and executes the Ansible playbook.

The first pipeline execution successfully configured the three servers. A subsequent execution produced zero Terraform changes and zero Ansible changes on all three hosts, demonstrating idempotency.

The final pipeline verification recorded:

- Terraform: No changes
- API: changed=0
- Payments: changed=0
- Logs: changed=0
- Failed hosts: 0
- Pipeline exit status: 0

## Verification

The final Terraform outputs provided the addresses and copyable SSH commands for all three servers. The final Ansible execution completed successfully with no configuration changes required.

The kk-payments service was also verified after applying the systemd hardening configuration. Its final security exposure score was 1.3, below the required maximum of 2.5, and the service started successfully.

