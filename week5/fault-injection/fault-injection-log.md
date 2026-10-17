# KijaniKiosk Pipeline Fault-Injection Log

## 1. Build Failure

**Fault injected:** Replaced the normal Build-stage dependency installation command with `sh 'npm ci --invalid-flag-intentional'`.

**Observed behaviour:** Initialize Metadata and Lint passed. The Build stage failed with exit code 2 because the shell attempted to open the command string as 
a file. Jenkins marked the overall pipeline as `FAILURE`. Verify, including Test and Security Audit, was skipped. Archive and Publish were also 
skipped. The Declarative Post Actions block ran and printed the pipeline failure messages.

**Artifact behaviour:** The Archive stage did not run, so this build did not create a new archived artifact through that stage. Publish did not run, so this 
build did not publish a package to Nexus.

**Conclusion:** The pipeline correctly stopped downstream stages after a Build-stage failure and reported the failure.

**Restoration:** Pending — restore the original Build command and verify a successful pipeline run.
