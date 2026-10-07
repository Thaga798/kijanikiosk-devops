# KijaniKiosk Staging Server Emergency Playbook
**Incident Responder:** Edwin Mathaga

"I have read the setup script. I understand what it does in general terms. I commit to treating the server as a black box during investigation and not 
referring back to the script until my runbook is complete."

## Phase 1: Performance Layer Findings

* **System I/O Wait (%wa):** 9.2 wa
* **Blocked Processes (b column from `vmstat`):** 0 0 0 0 0 0
* **Storage Device Saturation (%util):** vg-cpu:  %user   %nice %system %iowait  %steal   %idle
          16.2%    0.2%    4.1%    8.4%    0.0%   71.2%

### Performance Hypothesis

I suspect the 502 errors may be caused by heavy disk write activity. If the disks are saturated, large log files could be competing with the database for 
I/O and slowing down critical synchronous transactions and worker processes. My next step is to review the application logs and system journal to see whether 
the evidence supports or rules out this theory.

## Phase 2: Log Layer Findings

* **kk-payments Error Logs:** -- No entries --
* **Nginx Upstream Target Logs:**
* **Logrotate Strategy:**  log rotation configuration was found  missing

### Revised Working Hypothesis

I suspect the 502 errors may be related to a conflict involving the upstream service on port 3001, possibly made worse by high disk I/O caused by unrotated 
log files. This could be preventing the payment worker from maintaining a healthy listener and handling requests properly. My next step is to check the 
network port configuration and firewall rules to determine whether anything is interfering with connectivity to port 3001.

