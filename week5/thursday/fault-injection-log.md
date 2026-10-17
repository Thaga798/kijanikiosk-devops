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

## 3. Archive Failure

**Fault injected:** Changed the artifact archive pattern to reference a directory that does not exist, intentionally causing the Archive stage to fail.

**Observed behaviour:** Initialize Metadata, Build, and all three parallel Verify branches (Lint, Test, and Security Audit) completed successfully. The Archive stage encountered the intentional fault and failed because the expected artifact path was unavailable.

**Downstream stages:** Publish was skipped because the Archive stage failed. The Declarative Post Actions block still executed and reported the pipeline failure.

**Artifact behaviour:** The Build stage generated `dist/app.js`, but the Archive stage could not archive the expected files. Publish did not execute, so this run did not publish a new package to Nexus.

**Conclusion:** The test demonstrated that Jenkins detects an artifact-archiving failure and prevents the pipeline from continuing to publication. This helps avoid publishing a package when the required artifact-handling step has failed.

**Restoration:** The archive pattern was corrected, and a subsequent pipeline run completed successfully, confirming that the pipeline recovered after the injected fault was removed.

## 4. Publish Failure — Invalid Nexus Credentials

**Fault injected:** Changed the Nexus credential ID used by the Publish stage to an incorrect or nonexistent credential ID, intentionally preventing Jenkins from retrieving the required publishing credentials.

**Expected behaviour:** Initialize Metadata, Build, Verify, and Archive should complete successfully. The Publish stage should fail when Jenkins attempts to access the unavailable credential or authenticate with Nexus. The Declarative Post Actions block should still execute and report the failure.

**Expected artifact behaviour:** The artifact should be built and archived before publication is attempted. Because the Publish stage fails, the pipeline should not report a successful package publication. Depending on where the failure occurs, Nexus may reject the request before accepting any package.

**Conclusion:** This test checks that the pipeline handles publishing-credential failures and reports unsuccessful publication rather than treating the entire process as successful. It also demonstrates why Jenkins credentials must be configured correctly and referenced by their exact credential IDs.

**Restoration:** The original Jenkins credential ID, `nexus-credentials`, should be restored after the test. A subsequent pipeline run should complete successfully, and the console log should confirm successful publication to Nexus.

**Evidence to retain:** Record the failed build number, the Publish-stage error, the final pipeline status, and the successful recovery build number.


	## Required Thursday Fault-Injection Summary

| Fault | Observed (Y/N) | Explanation |
|---|---|---|
| Lint — introduce a syntax error in source code | Y | The Lint stage failed, and dependent downstream stages were skipped, preventing invalid code from proceeding through the pipeline. |
| Build — use an invalid `npm ci` flag | Y | The Build stage failed, causing Verify, Archive, and Publish to be skipped. |
| Test — introduce a deliberately failing assertion | Y | The Test branch failed while the independent Security Audit branch completed, demonstrating parallel execution and correct failure handling. Archive and Publish were skipped. |
| Publish — use an incorrect Jenkins credential ID | Y | Earlier stages and Archive completed, but Publish failed because the credentials could not be resolved, preventing successful publication to Nexus. |


