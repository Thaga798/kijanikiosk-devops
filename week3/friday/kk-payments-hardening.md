# Target Hardening Log: kk-payments.service

**Author:** Edwin Mathaga

## 1. Initial Hardening Assessment

* **Initial Exposure Score:** 9.6 / 10.0
* **Initial Status:** Unsafe / Exposed
* **Target Score:** Below 2.5

The service was initially running with
minimal sandboxing, resulting in a high
exposure score.

The hardening process was completed in
several stages to improve isolation while
keeping the payment service functional.

## 2. Hardening Progress

### Group 1 — Tuesday Baseline

Added:

* `NoNewPrivileges=true`
* `PrivateTmp=true`

**Resulting Score:** 7.2

These settings prevent the service from
gaining additional privileges and give it
a private temporary directory.

### Group 2 — Wednesday Baseline

Added:

* `ProtectSystem=strict`
* `ProtectHome=true`
* `ReadWritePaths=/opt/kijanikiosk/shared/logs`

**Resulting Score:** 4.1

This further restricted access to the host
filesystem while keeping the required logs
writable.

### Group 3 — Advanced Restrictions

Added:

* `MemoryDenyWriteExecute=true`
* `SystemCallFilter=@system-service`

**Resulting Score:** 2.9

These controls added additional protection
against unsafe memory execution and limited
the system calls available to the service.

### Group 4 — Production Shielding

Added:

* `PrivateDevices=true`
* `RestrictRealtime=true`

**Final Score:** 2.3

**Target achieved.**

The final configuration reduced the
exposure score below the required 2.5
threshold without removing functionality
required by the payment service.

## 3. Directives Tested and Rejected

Two additional systemd controls were tested
but were not enabled because they caused
operational issues.

### `ProtectKernelTunables=true`

This was rejected because the payment
processing workload needs to read certain
kernel runtime parameters.

During testing, enabling the setting caused
the Python worker to lose access to those
parameters and resulted in connection
timeouts during higher transaction loads.

### `PrivateNetwork=true`

This was also rejected.

The setting places the service in an isolated
network namespace and prevents normal network
communication.

The `kk-payments` service must communicate
with external payment gateways and receive
webhooks, so enabling this control would
break the payment flow.

## 4. Final Production Unit File

```ini
[Unit]
Description=KijaniKiosk Financial Payments Service
After=network-online.target kk-api.service
Wants=network-online.target kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kk-payments
WorkingDirectory=/opt/kijanikiosk/payments
ExecStart=/usr/bin/python3 \
  /opt/kijanikiosk/payments/processor.py

Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60s
StartLimitBurst=3

EnvironmentFile=/opt/kijanikiosk/config/payments-api.env

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
ProtectHome=true
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
SystemCallFilter=@system-service
PrivateDevices=true
RestrictRealtime=true

[Install]
WantedBy=multi-user.target
```

## 5. Final Status

The `kk-payments` service has been hardened
using systemd isolation and privilege
restrictions.

The final exposure score is **2.3**, which
meets the target threshold of below 2.5.

The two controls that affected required
payment functionality were intentionally
left disabled after testing.

The configuration therefore provides
stronger host isolation while preserving
the network and runtime access required by
the production payment service.
