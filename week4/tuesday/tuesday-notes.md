# Week 4 Tuesday - Terraform State and Deployment Notes

## Desired-State Verification

The deployed Multipass VM was compared with the desired-state
specification created on Monday.

The following requirements matched:

- VM name: kijanikiosk-api
- Operating system: Ubuntu 22.04.5 LTS
- CPU: 1 CPU
- Memory: approximately 1 GB
- VM IP: 10.139.243.128
- Network: 10.139.243.0/24
- Public IP: None
- SSH access: key-based access on port 22
- Environment: staging

Two discrepancies were identified.

First, the desired-state specification specified 10 GB of
root storage, while the Multipass VM currently reports
approximately 4.8 GiB of available disk space.

Second, the desired-state specification included an owner value
of "amina". The current Terraform configuration uses a
null_resource for the Multipass target, so it does not create
cloud-style resource tags such as an owner tag.

These differences were documented rather than treated as
successful matches.

## Terraform State Inspection

The Terraform state contains the following resource:

Resource type:
null_resource

Resource name:
kijanikiosk_api

Resource ID:
6339430250022353637

State trigger:
ip = 10.139.243.128

The resource ID was generated when Terraform created the
resource and was not known during the initial plan.

The IP address is recorded in the resource trigger and confirms
which Multipass VM the Terraform resource represents.

## State Inspection Commands

terraform state list

Result:

null_resource.kijanikiosk_api

terraform state show null_resource.kijanikiosk_api

The command showed the resource ID and the IP trigger recorded
in Terraform state.

The raw terraform.tfstate file was also inspected to confirm
that the resource type is null_resource.

## Deployment Result

Terraform successfully connected to the Multipass VM using SSH
and executed the remote-exec provisioner.

The provisioner returned the VM hostname and Linux kernel
information.

The Terraform output reported:

api_server_ip = "10.139.243.128"
