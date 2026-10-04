# KijaniKiosk API Server - Desired State Specification

## Identity
- Name: kijanikiosk-api-staging
- Environment tag: staging
- Owner tag: amina

## Compute
- Provider: Multipass (local)
- Region: N/A - local development environment
- Instance type: 1 CPU, 1GB RAM, 10GB disk
- Operating system: ubuntu-22.04-lts (exact image ID: 22.04)

## Networking
- VPC: N/A - Multipass local networking
- Subnet: N/A - Multipass local networking
- Assign public IP: no

## Access Control
- SSH access: port 22, source local host/network only
- HTTP access: port 80, source 0.0.0.0/0
- All other inbound: deny
- All outbound: allow

## Storage
- Root volume: 4.8GB, type default Multipass disk

## Authentication
- SSH key pair name: Multipass-managed/local SSH access

## What must NOT exist on this server after provisioning
- No default password authentication
- No services listening other than sshd
- No world-writable directories outside /tmp

## Open questions
- What Terraform provider should be used to represent the local Multipass VM?
- What exact Terraform mechanism will be used to provision/manage the Multipass instance?
- How will the local Multipass network be represented in Terraform?
- How will the SSH access restriction be represented for a local VM?
- Should HTTP port 80 actually be opened at this stage if no web service is running yet?


### Hardest Decision: Choosing the Instance Type
The hardest decision I faced was choosing the right instance type for the KijaniKiosk API server. I needed enough CPU and memory for the server to run properly without giving it more resources than necessary.

I decided on 1 CPU and 1 GB of RAM, but the exact instance type can be different depending on the cloud provider. This showed me why Terraform variables are useful because the instance type can be changed without rewriting the whole configuration.

This also helped me understand that the desired-state specification should describe what I want the server to have, while Terraform handles how that state is created.


