# KijaniKiosk Systemd Security Hardening Assessment

**Author:** Edwin Mathaga

## 1. Selected Directives

To improve the security of the `kk-api.service`, we added two
systemd sandboxing options:

* `MemoryDenyWriteExecute=true`
* `SystemCallFilter=@system-service`

These settings add extra restrictions around what the application
process can do while it is running.

## 2. Why These Settings Were Added

### MemoryDenyWriteExecute=true

This prevents the service from creating memory that is both writable
and executable at the same time.

The main benefit is reducing the risk of certain memory-based attacks,
where an attacker tries to place and execute code inside the process.
It adds another layer of protection if the application has a memory
safety issue.

### SystemCallFilter=@system-service

This limits the system calls available to the service to those normally
needed by a system service.

The goal is to prevent the application from accessing unnecessary
low-level kernel functionality. If the application is compromised, this
restriction can reduce what the attacker can do through the service
process.

## 3. Overall Reasoning

These directives do not replace application-level security, but they
provide additional isolation at the systemd level. If the `kk-api`
process is compromised, the attacker has fewer capabilities available
to use against the rest of the system.
