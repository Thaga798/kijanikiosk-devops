# KijaniKiosk CI Pipeline — Board Briefing

## Purpose

The KijaniKiosk Payments pipeline provides a repeatable way to check, package, and publish application changes. Its purpose is to catch problems before a package reaches the shared Nexus repository. This reduces avoidable manual work and makes each release easier to trace to the code that produced it.

The pipeline runs through Jenkins and uses a pinned Node.js 18 build-agent image. It installs project dependencies, checks code quality, builds the application, runs tests and a security audit, archives the build output, and publishes the package. The published version includes the application version and the Git commit identifier.

## How a Change Becomes a Package

The pipeline follows this sequence:

```text
Checkout and initialize version
              |
             Lint
              |
            Build
              |
     +--------+---------+
     |                  |
   Tests          Security audit
     |                  |
     +--------+---------+
              |
            Archive
              |
            Publish
              |
        Nexus repository
```

| Stage | What it does | Why it matters |
|---|---|---|
| Initialize Metadata | Reads the application version and short Git commit ID. | Connects the package to a specific code revision. |
| Lint | Checks the code using the project's lint command. | Finds code-quality problems early. |
| Build | Installs dependencies and generates the `dist` output. | Confirms the application can be built and that the expected output exists. |
| Verify | Runs tests and a security audit in parallel. | Checks application behaviour and reports high-severity dependency vulnerabilities. |
| Archive | Stores the build output and records fingerprints. | Keeps build evidence and helps track archived files. |
| Publish | Publishes the versioned package to Nexus using credentials stored in Jenkins. | Makes the package available in the shared repository. |

## Friday Delivery Result

The successful Friday run was Jenkins build #83 on branch `feature/week5-ci-pipeline`, commit `b66d5d6437ac6dd90a42ee3e9e674cb38741c1b7`. It completed in 6 minutes and 36 seconds, within the required ten-minute limit.

Lint and Build passed. The Test stage reported one passing test and no failures. The Security Audit reported zero vulnerabilities at the configured audit threshold. Archive completed with fingerprinting, and Publish successfully uploaded `kijanikiosk-payments@1.0.0-b66d5d6` to Nexus.

The repository evidence also shows an earlier package version, `1.0.0-403f9af`, alongside the Friday version. This demonstrates that the repository retains packages from different code revisions rather than only the latest package.

## What Happens When Something Goes Wrong

The pipeline stops the delivery process when a required check fails. If the code-quality check, build, tests, security audit, or archiving step fails, later delivery steps do not proceed. This prevents a failed run from being treated as a successful release.

Fault-injection exercises were used to check failure handling. The recorded tests include a Build failure, a forced failure in the parallel Lint branch, an Archive failure, and a Publish failure caused by an incorrect credential reference. The records describe downstream steps being skipped and the failure being reported. After the intentional faults were removed, a successful run confirmed recovery.

A failed run does not mean that a new package was successfully published. The team should inspect the reported failure, correct the cause, and run the checks again before treating a package as ready for delivery.

## Credential Handling and Evidence

Publishing credentials are referenced through a stored credential entry rather than written as a literal password in the pipeline file. The publishing step creates temporary npm configuration for authentication and removes it within the same shell step. The credential audit found no tracked `.npmrc` files and no obvious hardcoded password in the current pipeline file. These checks reduce risk but do not guarantee that every possible secret is absent from all historical files or logs.

The Friday evidence includes the successful-run record, the Nexus versions screenshot, the fault-injection log, and the credential audit. Together, these provide a record of the delivery result and the checks performed.

## Current Scope and Next Steps

This is a working coursework delivery pipeline, not yet a complete production-release system. The current test evidence includes one automated test, and the dependency audit is only one part of application security. The pipeline also does not provide a configured external alerting service or deploy the application to a production environment.

Before production use, the team should expand automated test coverage, introduce broader security scanning, configure reliable failure notifications, protect release approvals, and test deployment and rollback procedures. These improvements would provide stronger confidence that a published package is safe to operate and support.
