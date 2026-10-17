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

## 2. Parallel Verify Failure — Lint Branch

**Fault injected:** Added an intentional `exit 1` immediately after `npm run lint` in the Lint branch of the parallel Verify stage. The injected message was `Intentional fault: forcing Lint branch to fail`.

**Commit tested:** `682e3b1` — `test: inject intentional parallel lint failure`.

**Observed behaviour:** Initialize Metadata and Build passed. During the parallel Verify stage, the Lint branch failed with exit code 1 as intended. The Test branch completed successfully, and the Security Audit branch completed successfully with zero vulnerabilities. This confirmed that the other parallel branches could finish even when Lint failed.

**Downstream stages:** Archive and Publish were skipped because of the earlier failure. The Declarative Post Actions block still ran and printed the pipeline failure messages.

**Artifact behaviour:** The Build stage created `dist/app.js`, but Archive and Publish did not execute during this run. Therefore, this run did not archive or publish a new artifact through those stages.

**Conclusion:** Jenkins correctly propagated the Lint failure to the overall pipeline while allowing the other parallel verification branches to complete. The pipeline prevented downstream artifact handling and publication after verification failed.

**Final status:** `FAILURE`, as expected.

**Restoration:** Remove the intentional `echo` and `exit 1` commands, restore the Lint branch to its normal `npm run lint` command, and verify that the pipeline returns to `SUCCESS`.
