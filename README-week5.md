# Week 5 — KijaniKiosk CI/CD Pipeline

## Overview

Week 5 focused on improving the KijaniKiosk Payments project by building and testing a CI/CD pipeline. The work covered Git workflows, Docker-based build environments, automated testing, security checks, artifact publishing, and pipeline failure handling.

The work is organized by day. Some tasks were completed on separate Git branches, so checking only the `master` or `develop` branch may not show every deliverable.

## Tuesday — Docker Build Agent and CI Setup

Tuesday's work focused on improving the build environment and preparing the project for automated integration. A Docker-based Node.js environment helps keep builds consistent and reduces dependence on software installed directly on the host machine.

Key areas included:
- Preparing the Docker build-agent configuration.
- Working with the application source and Jenkins pipeline.
- Reviewing Git workflows and CI configuration.
- Preparing the project for automated linting, building, and testing.

**Where to find the work:**
- Branch: `feature/week5-docker-agent`
- `ci/Dockerfile` — Docker build-agent configuration.
- `Jenkinsfile` — Jenkins pipeline configuration.
- `.github/workflows/ci.yml` — GitHub Actions workflow.
- `src/app.js` — application source.
- `notes/tuesday-git.md` — Git workflow notes.

## Wednesday — Nexus Artifact Publishing

Wednesday focused on publishing versioned application packages to Nexus. The pipeline was used to build and publish an artifact, while the evidence documented the publishing result and credential-handling practices.

Key areas included:
- Publishing the KijaniKiosk Payments package to Nexus.
- Recording build output and artifact details.
- Checking that credentials were handled without exposing the password.
- Capturing evidence for the coursework submission.

**Where to find the work:**
- Branch: `feature/week5-wednesday`
- `week5/wednesday/publish-build-log.txt` — publishing build evidence.
- `week5/wednesday/nexus-artifact-screenshot.png` — Nexus artifact evidence.
- `week5/wednesday/credential-audit.txt` — credential audit.
- `week5/wednesday/reflection.md` — reflection on the day's work.

## Thursday — Pipeline Design and Fault Injection

Thursday focused on reviewing the pipeline and testing how it responds when stages fail. Fault injection was used to check whether failures were reported correctly and whether later delivery stages were prevented from running after an earlier failure.

Key areas included:
- Reviewing the pipeline design.
- Testing Build, verification, Archive, and Publish failure scenarios.
- Checking how the pipeline handles failures and recovery.
- Recording the results and reflecting on the implementation.

**Where to find the work:**
- Branch: `feature/week5-docker-agent`
- `week5/thursday/Jenkinsfile` — Thursday pipeline version.
- `week5/thursday/fault-injection-log.md` — recorded failure tests.
- `week5/thursday/pipeline-design-review.md` — design review.
- `week5/thursday/reflection.md` — reflection.
- `week5/thursday/green-pipeline-log.txt` — successful pipeline evidence.

## Friday — Final CI Pipeline and Delivery Evidence

Friday brought the pipeline work together into a final delivery workflow. The pipeline performs linting, builds the application, runs tests and a security audit in parallel, archives the build output, and publishes the versioned package to Nexus.

The successful Jenkins build was **#83**. It completed in 6 minutes and 36 seconds and published `kijanikiosk-payments@1.0.0-b66d5d6`.

Key areas included:
- Completing the final Jenkins pipeline.
- Verifying linting, build, tests, and dependency security checks.
- Archiving and fingerprinting build artifacts.
- Publishing the package to Nexus using Jenkins-managed credentials.
- Documenting fault-injection results and auditing credential handling.

**Where to find the work:**
- Branch: `feature/week5-ci-pipeline`
- `Jenkinsfile` — final pipeline definition at the repository root.
- `week5/friday/ci-pipeline-board-document.md` — board-level explanation of the pipeline.
- `week5/friday/green-pipeline-run.txt` — successful build evidence.
- `week5/friday/nexus-versions-screenshot.png` — Nexus package versions.
- `week5/friday/fault-injection-log.md` — fault-injection results.
- `week5/friday/credential-audit.txt` — credential audit.

