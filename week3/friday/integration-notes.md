# Integration Challenge Resolutions

## KijaniKiosk Production Baseline

**Author:** Edwin Mathaga

## Challenge A: ProtectSystem and EnvironmentFile

**Issue:**

`ProtectSystem=strict` makes the system
configuration paths read-only for the
service.

When secrets were stored under
`/etc/kijanikiosk/`, the service could not
load them correctly during startup.

**Resolution:**

We moved the production environment files
to:

`/opt/kijanikiosk/config/`

The service can read the required
environment files while the rest of the
system remains protected.

Write access is only provided where it is
actually required, such as the application
logging directories.

## Challenge B: Monitoring User and File Access

**Issue:**

The health-check process runs with root
privileges.

As a result, generated files such as
`last-provision.json` were owned by
`root:root`.

This prevented low-privilege monitoring
users, including `amina`, from reading the
health statistics.

**Resolution:**

We created a dedicated health directory
under:

`/opt/kijanikiosk/`

The health-check script sets the required
ownership and permissions:

```bash
chown kk-logs:kijanikiosk last-provision.json
chmod 640 last-provision.json
```

This allows approved users to access the
metrics without giving the file global
read permissions.

## Challenge C: logrotate and PrivateTmp

**Issue:**

With `PrivateTmp=true`, the service receives
its own isolated `/tmp` environment.

Temporary files or signals created by
`logrotate` outside that namespace cannot
be used reliably for communication with the
service.

**Resolution:**

We removed the temporary-file signalling
approach.

The `logrotate` configuration now uses
systemd to control the required service:

```bash
/usr/bin/systemctl reload nginx
```

This keeps the reload operation on the
systemd control path instead of relying on
shared temporary files.

## Challenge D: Dirty VM and Package Holds

**Issue:**

A VM with unexpected package changes can
cause problems during provisioning.

For example, running a blind
`apt-get install` against a modified VM
could result in unwanted package changes
or version conflicts.

**Resolution:**

The provisioning process now includes
explicit package validation.

After the required packages are installed,
Phase 1 applies the required package holds
using:

```bash
apt-mark hold
```

Before provisioning is completed, Phase 6
checks the package holds again.

If the expected version controls are
missing, the process fails instead of
continuing with an unsafe configuration.

## Final Status

The integration issues were addressed
without removing the required security
controls.

The final baseline provides:

* Protected system directories
* Controlled secret-file access
* Restricted monitoring permissions
* Isolated temporary directories
* Systemd-based service control
* Package version protection
* Validation checks during provisioning

These changes make the production baseline
more predictable while maintaining the
required security boundaries.
