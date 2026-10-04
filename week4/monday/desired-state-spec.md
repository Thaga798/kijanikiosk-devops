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

#### Hardest Decision and Why

The hardest decision was determining how to represent the networking and access-control requirements because the assignment is written using cloud concepts 
such as VPCs, subnets, security groups, and public IP addresses, while I am using Multipass locally because I do not have an AWS account. I was 
therefore unsure whether I should try to assign AWS-style values to the local VM or treat those concepts as not applicable. I decided to document the local 
Multipass networking honestly rather than invent cloud resources that do not exist. The VM has a private IP address and does not have a public IP, while 
UFW can provide the host-level firewall controls. This decision will need to be made explicit in the Terraform configuration because Terraform will require 
me to define exactly what infrastructure and networking resources are being managed.

