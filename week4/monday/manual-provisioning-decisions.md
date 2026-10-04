# Manual Provisioning Decisions - KijaniKiosk API Server

| Decision          | Value I chose                         | Reason |
|-------------------|---------------------------------------|--------|
| Cloud provider    | Local / Multipass                     | No AWS account; Multipass provides the Ubuntu VM locally. |
| Region            | N/A                                   | The VM is running locally, so no cloud region is required. |
| Operating system  | Ubuntu 22.04 LTS                      | Required by the assignment. |
| Instance type     | Smallest practical Multipass VM      | Provides a lightweight VM suitable for the API server. |
| VPC               | N/A / Multipass networking            | Multipass manages the VM's local networking. |
| Subnet            | N/A / Multipass networking            | No AWS subnet is being created. |
| Security group    | UFW inside VM                         | Provides firewall rules and controls network access to the server. |
| SSH key pair      | Local SSH key                         | Used to securely access the Multipass VM. |
| Root volume size  | 4.8 GB                                 | Provides sufficient storage for the Ubuntu OS and KijaniKiosk API server. |
| Public IP?        | No                                    | The VM is local and is not publicly exposed. |
| Tags / labels     | kijanikiosk-week4                     | Identifies the VM as the KijaniKiosk Week 4 API server. |



