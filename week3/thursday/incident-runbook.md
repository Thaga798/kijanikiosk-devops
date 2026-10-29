# Incident Resolution Playbook: Staging Server Latency & 502 Remediation

**Responder:** Edwin Mathaga
**Date:** September 27, 2026

## 1. Incident Summary

The staging environment experienced intermittent HTTP 502 Bad Gateway exceptions affecting the core payments endpoint. The investigation was initiated at 19:30 using diagnostic tools to treat the cluster node as a black box.

## 2. Layer Investigation Telemetry

* **Performance Layer:** System analysis via `iostat` and `vmstat` revealed extreme disk I/O saturation (`%wa > 50%`) with multiple processes blocked. The shared application log folder `/opt/kijanikiosk/shared/logs/` was bloated to 2GB due to unrotated logs.
* **Log Layer:** Application logs showed recurring worker connection failures and timeouts. The system lacked an active logrotate template configuration.
* **Network Layer:** Running `ss -tlnp` caught a port conflict on Port 3001 caused by a rogue test script process intercepting traffic meant for `kk-payments`. A misconfigured UFW firewall entry (`deny 3001/tcp`) was blocking system health check probes.

## 3. Root Cause Analysis

1. **Rogue Service Port Collision:** An orphaned test execution path was listening on Port 3001, intercepting API traffic and returning generic internal 500 crashes instead of handling payment processing.
2. **Health Check Firewall Lockout:** A misconfigured firewall directive explicitly blocked Port 3001 traffic, causing health check system monitors to mark the node as dead.
3. **Storage I/O Saturation:** The lack of a daily log rotation policy allowed historical transaction logs to grow to 2GB. This saturated disk write threads and caused thread blocks.

## 4. Remediation Execution Trace

* **Step 1:** Gracefully terminated the rogue process on Port 3001 using `kill -TERM`. This instantly restored routing pathways to the correct payment daemon.
* **Step 2:** Executed `ufw delete` to clear the erroneous block on Port 3001, restoring monitoring visibility.
* **Step 3:** Created a daily log rotation configuration file (`/etc/logrotate.d/kijanikiosk`) and ran `logrotate --force` to reclaim disk space and drop the I/O wait metrics below 10%.

## 5. Architectural Fix Order Rationale

We executed **Fix 1 (Port conflict)** first because it provided an immediate fix for the 502 error rate with zero risk of data loss. **Fix 2 (Firewall)** followed second to restore load balancer visibility. **Fix 3 (Log Rotation)** was left for last because running file compression utilities on a system already experiencing high disk I/O wait metrics would spike latency further.

If the firewall was unblocked before killing the rogue server, the monitoring engine would have marked the broken test script as healthy, routing real user traffic to an interface designed to return 500 errors.

## 6. Prevention Design Strategy

The `kijanikiosk-provision.sh` blueprint has been updated to build daily log rotation profiles and include explicit structural code comments that prevent any accidental injection of Port 3001 deny rules in the future.
