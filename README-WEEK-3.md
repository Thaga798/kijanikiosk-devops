# KijaniKiosk DevOps Engineering Project

This repository contains the DevOps and Linux systems engineering work completed for the **KijaniKiosk platform**.

The project covers Linux administration, security hardening, infrastructure automation, service isolation, firewall configuration, Git/GitHub workflows, CI, and cloud architecture.

## Important: Start Here

Not all of the Week 3 implementation has been merged into `master`.

The work was developed in separate feature branches, so **please do not assess the project using the `master` branch alone**. The feature branches contain implementation work that is not currently present in `master`.

### Week 3 branches

| Area                  | Branch                                 | PR | Focus                                       |
| --------------------- | -------------------------------------- | -: | ------------------------------------------- |
| Monday                | `feature/week3-monday-triage`          | #2 | Performance and process investigation       |
| Tuesday               | `feature/week3-tuesday-security`       | #3 | Linux security, users, permissions and ACLs |
| Wednesday             | `feature/week3-wednesday-provisioning` | #3 | Idempotent provisioning and automation      |
| Thursday              | `feature/week3-thursday-incident`      | #4 | Systemd hardening and network security      |
| Production Foundation | `feature/week3-production-foundation`  | #5 | Main Project(Production infrastructure and automation)    |

> Some Pull Requests contain related work from more than one task. For the full picture, review both the branch contents and the Pull Request history.

---

## Week 3 Work

### Monday — Performance & Process Triage

**Branch:** `feature/week3-monday-triage`
**PR:** #2

The Monday task focused on investigating an application environment experiencing a **502 Bad Gateway** error.

The investigation included:

* CPU and I/O wait
* Memory and disk usage
* Running processes
* TCP listeners using `ss`
* Application log growth
* Graceful process termination

The investigation identified an oversized application log at:

```text
/opt/kijanikiosk/logs/api.log
```

A problematic background process was also investigated and terminated using `SIGTERM`.

---

### Tuesday — Linux Security & ACLs

**Branch:** `feature/week3-tuesday-security`
**PR:** #3

Tuesday focused on reducing unnecessary privileges and controlling access to application files and directories.

The implementation included:

* Dedicated system/service accounts
* `/usr/sbin/nologin`
* POSIX permissions
* SGID shared directories
* Extended ACLs
* Default ACLs

For example, shared logging access was configured using permissions and ACLs rather than giving users broader access than necessary.

Additional Git notes are available in:

```text
notes/tuesday-git.md
```

---

### Wednesday — Idempotent Provisioning

**Branch:** `feature/week3-wednesday-provisioning`
**PR:** #3

Wednesday focused on making infrastructure setup repeatable and safe to run multiple times.

The provisioning scripts use:

```bash
set -euo pipefail
```

and check the existing system state before making changes.

For example, user creation checks whether an account already exists before attempting to create it.

The main goal was **idempotent automation**: running the provisioning process again should bring the system to the desired state without unnecessarily breaking or recreating existing resources.

---

### Thursday — Systemd & Network Hardening

**Branch:** `feature/week3-thursday-incident`
**PR:** #4

Thursday focused on hardening application services and controlling network access.

Systemd service configuration included security settings such as:

```ini
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
SystemCallFilter=@system-service
```

UFW was also configured to control access between public and internal services.

Particular attention was given to:

* Protecting the internal application port (`3001/tcp`)
* Allowing required monitoring traffic
* Monitoring subnet `10.0.1.0/24`
* Removing unnecessary firewall rules
* Separating public and internal services

---

### Project: Production Server Foundation

**Branch:** `feature/week3-production-foundation`
**PR:** #5

This branch builds on the earlier security and provisioning work and focuses on creating a more repeatable production foundation.

Areas covered include:

* Infrastructure automation
* System configuration
* Service configuration
* Security configuration
* Package management
* Desired-state management

Package holds were also explored for components such as:

```bash
apt-mark hold nginx nodejs
```

---

## Git & Pull Request Workflow

The project was developed using feature branches rather than putting all implementation directly into `master`.

The general workflow was:

```text
Feature branch
      ↓
Implementation
      ↓
Pull Request
      ↓
Review / commits
      ↓
Master (where applicable)
```

Because some branches have not been merged, the **feature branches and Pull Requests are part of the project evidence**.

---

## CI

The repository includes a GitHub Actions workflow:

```text
.github/workflows/ci.yml
```

The workflow performs basic repository validation, including checking that required documentation is present.

CI results can be viewed under:

```text
GitHub → Actions
```

---

## Cloud Architecture

The proposed cloud architecture is documented in:

```text
cloud-architecture.md
```

It covers topics including:

* PaaS options
* AWS Cape Town
* Azure Johannesburg
* Availability Zones
* High availability
* Multi-region deployment
* Infrastructure trade-offs

The document discusses the benefits and additional operational complexity of running workloads across multiple availability zones or regions.

---

## Operational Runbook

Operational procedures are documented in:

```text
RUNBOOK.md
```

The runbook covers common tasks such as:

* Checking system status
* Viewing logs
* Managing processes
* Managing log files
* Rolling back changes

---

## Repository Structure

```text
kijanikiosk-devops/
├── .github/
│   └── workflows/
│       └── ci.yml
├── README.md
├── RUNBOOK.md
├── cloud-architecture.md
├── notes.md
├── notes/
│   └── tuesday-git.md
└── week3/
    └── Week 3 implementation
```

The exact implementation files should be reviewed from their respective feature branches.

---

## Suggested Assessment Order

For a complete review, I recommend the following order:

1. **README** — project overview
2. **Monday branch / PR #2** — performance investigation
3. **Tuesday branch / PR #3** — Linux security and ACLs
4. **Wednesday branch / PR #3** — provisioning and idempotency
5. **Thursday branch / PR #4** — systemd and network hardening
6. **Production Foundation / PR #5** — production automation
7. **CI workflow** — `.github/workflows/ci.yml`
8. **Cloud architecture** — `cloud-architecture.md`
9. **Runbook** — `RUNBOOK.md`

This provides the progression of the project from:

**diagnosis → security → automation → hardening → production foundation**

---

## Repository

**GitHub:**
https://github.com/Thaga798/kijanikiosk-devops

### Assessment Note

The `master` branch contains the main project documentation and supporting files, but it does **not** represent all of the Week 3 implementation.

For a complete assessment, review both the `master` branch and the Week 3 feature branches/ Pull Requests listed above.
