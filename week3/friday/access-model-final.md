# Production Access Model Layout

## Audit and Permissions Mapping

**Author:** Edwin Mathaga

This section documents the directory
structure, ownership, and access controls
used across the production environment.

## 1. Directory and Permissions Matrix

| Path                            | Owner         | Group         | Mode   | ACL                             |
| ------------------------------- | ------------- | ------------- | ------ | ------------------------------- |
| `/opt/kijanikiosk/api/`         | `kk-api`      | `kk-api`      | `750`  | `amina:r-x`                     |
| `/opt/kijanikiosk/payments/`    | `kk-payments` | `kk-payments` | `750`  | `amina:r-x`                     |
| `/opt/kijanikiosk/config/`      | `root`        | `kijanikiosk` | `750`  | `edwin:r--`, `amina:r--`        |
| `/opt/kijanikiosk/shared/logs/` | `kk-logs`     | `kk-logs`     | `2770` | `kk-api:rwx`, `kk-payments:r-x` |
| `/opt/kijanikiosk/health/`      | `kk-logs`     | `kijanikiosk` | `750`  | `last-provision.json:640`       |

The permissions are designed to give each
service only the access it needs.

Application directories remain restricted
to their respective service accounts.

Configuration files are protected from
unnecessary write access, while approved
users can read the required settings.

The shared log directory allows the
application services to write or read logs
as required.

## 2. Logrotate Permission Handling

Log rotation must not accidentally change
the access model.

The shared log directory therefore uses
default POSIX ACLs through `setfacl -d`.

This ensures that newly created log files
inherit the required permissions for:

* `kk-api`
* `kk-payments`

As a result, permissions remain consistent
after log rotation instead of relying on
manual correction.

## 3. Audit Considerations

The access model provides:

* Separate ownership per service
* Restricted directory permissions
* Controlled ACL-based access
* Limited configuration access
* Shared logging with defined permissions
* Consistent permissions after rotation

