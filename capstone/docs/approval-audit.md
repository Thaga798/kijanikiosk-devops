# Production Approval Audit

## Purpose

This document records the human approval required before a staging
deployment can proceed to production.

## Approval process

1. Jenkins deploys the application to the staging namespace.
2. Jenkins waits for the staging Deployment rollout.
3. Jenkins runs the staging health check.
4. The production security checklist is presented for review.
5. An authorized reviewer approves or rejects production deployment.
6. Jenkins records the approver and the reason supplied.
7. Production deployment proceeds only after approval.

## Approval evidence

The Jenkins build log should retain:

- Jenkins job and build number.
- Staging rollout result.
- Staging smoke-test result.
- Approver identity.
- Approval reason.
- Production rollout result.
- Production smoke-test result.

## Current implementation status

The approval stages are defined in the capstone Jenkinsfile.
The pipeline has not yet been executed in Jenkins.
Actual approval evidence must be added after a successful pipeline run.
