# KijaniKiosk Infrastructure Security Hardening Decisions

## Purpose

This document records the security decisions made for the KijaniKiosk Week 4 Infrastructure as Code pipeline. The objective is to establish a repeatable security baseline across the API, payments, and logging servers while keeping the configuration suitable for automated deployment.

The implementation uses infrastructure automation so that the same controls are applied consistently to every server. Security decisions were selected to reduce unnecessary exposure, restrict service privileges, protect sensitive application resources, and maintain predictable behaviour during repeated deployments.

## Infrastructure Security Decisions

Network access is restricted by default. Incoming traffic is denied unless it is explicitly required, while necessary administrative access remains available. Service access is limited to the required local interfaces and ports. This reduces the number of externally reachable services and limits opportunities for unauthorized access.

SSH access relies on a key pair rather than password-based authentication. The private key remains on the deployment workstation and is referenced through configuration variables rather than being embedded in the inventory. This supports controlled administrative access while avoiding credentials in the repository.

Terraform state is stored remotely in the local MinIO S3-compatible service. Remote state provides a shared source of infrastructure information and prevents the deployment process from depending solely on a local state file. The development configuration does not provide native state locking through MinIO, so concurrent Terraform operations must be avoided. A production deployment should use a backend with supported state locking.

## Service Hardening

The KijaniKiosk services run using dedicated non-privileged service identities. This limits the consequences of a service compromise because the process does not receive unnecessary administrative privileges.

The systemd configuration applies multiple isolation controls. New privileges are disabled, access to user home directories is restricted, temporary storage is isolated, and the system filesystem is protected from modification. Writable access is limited to the application logging area required by the service.

The payments service receives additional restrictions because payment processing is a sensitive application function. Device access is restricted and network address families are limited to the protocols required by the service. Kernel, namespace, process, and privilege-related restrictions further reduce the available attack surface.

Environment-specific application configuration is supplied separately from the service definition. This supports the required relationship between strong filesystem protection and configuration supplied through an environment file under the application configuration area.

## Security Control Decisions

| Control | What it does | Risk mitigated |
|---|---|---|
| Security groups / network ingress | Restricts inbound traffic to explicitly required access | Unnecessary network exposure |
| SSH key pair | Provides key-based administrative authentication | Password attacks and weak credentials |
| Remote Terraform state | Stores infrastructure state centrally | State loss and inconsistent deployments |
| State locking limitation | Documents the lack of native locking in the local MinIO path | Concurrent state modification |
| NoNewPrivileges | Prevents processes from gaining additional privileges | Privilege escalation |
| ProtectSystem | Makes system areas unavailable for routine modification | System tampering |
| PrivateTmp | Gives the service an isolated temporary area | Temporary-file attacks |
| PrivateDevices | Restricts access to device nodes | Hardware and device abuse |
| ProtectHome | Restricts access to user home directories | Exposure of user data |
| CapabilityBoundingSet | Removes unnecessary Linux capabilities | Privileged operations |
| RestrictNamespaces | Limits creation of additional namespaces | Isolation bypass |
| ProtectKernelModules | Prevents service interaction with kernel modules | Kernel-level tampering |
| ProtectKernelTunables | Protects kernel tuning interfaces | Host configuration manipulation |
| ProtectControlGroups | Restricts control-group manipulation | Resource-control abuse |
| RestrictSUIDSGID | Restricts creation or manipulation of privileged file attributes | Privilege escalation |
| SystemCallArchitectures | Limits system-call architecture choices | System-call attack surface |
| MemoryDenyWriteExecute | Prevents writable memory from becoming executable | Code-injection techniques |

## Verification and Reproducibility

The security configuration is deployed through Ansible templates rather than manually configured on individual machines. This ensures that the same systemd hardening controls are applied consistently to all relevant servers.

The kk-payments service was verified after deployment and achieved a final security exposure score of 1.3, which is below the required maximum of 2.5. The service also started successfully after the hardening configuration was applied.

The final pipeline execution demonstrated idempotency. Terraform reported that no infrastructure changes were required, while Ansible reported changed=0 for the API, payments, and logs servers. This confirms that the configuration can be executed repeatedly without introducing unnecessary modifications.

## Current Limitations

The primary development limitation is the use of local MinIO for Terraform remote state. Although it provides persistent S3-compatible storage, the selected configuration does not provide native Terraform state locking. This means concurrent infrastructure operations should be avoided. For production use, the project should migrate to a backend that provides supported state locking and stronger operational guarantees. Additional production controls would include centralized secret management, continuous security monitoring, formal backup procedures, and controlled access to infrastructure credentials.
