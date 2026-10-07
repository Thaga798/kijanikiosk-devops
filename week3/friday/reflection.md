# Infrastructure Engineering Reflection

## Retrospective

**Author:** Edwin Mathaga
**Date:** September 28, 2026

## 1. Architectural Requirement Conflicts

During integration, we found a conflict
between `ProtectSystem=strict` and the way
our environment configuration files were
being loaded.

`ProtectSystem=strict` makes host system
directories, including `/etc/`, read-only
for the isolated service.

During early testing, configuration files
were stored under:

`/etc/kijanikiosk/`

When the service started, systemd blocked
the required file access. The resulting
error was not very clear and initially
looked like a connection failure.

This showed me that sandboxing controls
cannot be tested separately from the
application's filesystem requirements.

We moved the configuration files to:

`/opt/kijanikiosk/config/`

and adjusted the service paths accordingly.

This resolved the issue while keeping the
filesystem restrictions in place.

## 2. Translating Security Controls

The same security control can be explained
differently depending on the audience.

### Business / Compliance View

> "Locks down the host operating system
> directories to read-only status to
> prevent malicious software changes and
> persistent backdoors."

This focuses on the business risk and the
reason the control matters.

### Technical Infrastructure View

> "`ProtectSystem=strict` restricts write
> access to system files, while an empty
> `CapabilityBoundingSet=` removes
> unnecessary Linux capabilities."

This version explains the actual systemd
controls used by the infrastructure team.

### What Changes Between the Two?

The business explanation is easier to
understand but leaves out implementation
details.

The technical explanation is more precise
and useful for engineers who need to deploy,
test, or audit the configuration.

The main lesson is that security controls
need to be explained according to the
audience without losing their actual
security purpose.

## 3. Production Fragility Risk

The most fragile part of the current
foundation script is the **Phase 1 package
repository and version-pinning process**.

The script currently depends on external
package sources and live `apt-get update`
operations.

This creates several possible failure
points.

For example:

* An external repository could become
  unavailable.
* A GPG signing key could change.
* Package metadata could change.
* Network connectivity could fail.
* A package version could be removed.

Any of these issues could cause the
provisioning process to fail.

## 4. Recommended Improvement

For a more reliable production setup, we
should reduce direct dependency on external
package repositories.

A better approach would be to use internal
package mirrors or repositories, such as:

* JFrog Artifactory
* Sonatype Nexus
* Aptly

These repositories could be hosted inside
the organization's private network.

The provisioning process would then pull
approved packages from internal sources
instead of relying directly on external
internet repositories.

This would give us better control over
package versions and make provisioning more
predictable and repeatable.

## 5. Key Takeaway

The main lesson from this work is that
security hardening must be balanced with
operational requirements.

A control may improve isolation while also
changing how an application accesses files,
networks, or system resources.

Testing these controls together with the
application and deployment process is
therefore essential before moving the
configuration into production.
