# AI Governance Log

This log records AI assistance used during the KijaniKiosk capstone.
AI-generated suggestions were reviewed before being applied.

| Date | Tool | Task | Context and prompt | AI contribution | Review and changes |
|---|---|---|---|---|---|
| 2026-11-12 | ChatGPT | Kubernetes configuration | Reviewed staging and production deployment requirements. | Suggested namespace isolation, ConfigMaps, Secrets, probes, resources, Services and Ingress. | Compared suggestions against the actual manifests and cluster output before applying changes. |
| 2026-11-12 | ChatGPT | Error-rate monitoring | Requested a log-based check for HTTP 5xx responses above a 5% threshold. | Suggested a shell script to calculate the error rate from Ingress controller logs. | Corrected the access-log status field to `$9` and tested both successful traffic and a synthetic 503 failure. |
| 2026-11-12 | ChatGPT | Deployment pipeline | Requested a Jenkins pipeline with staging deployment, smoke testing and human production approval. | Suggested a Declarative Pipeline with rollout checks and an approval input. | Reviewed namespace handling against the actual YAML manifests. Pipeline remains untested because Jenkins is not running. |

## Governance principles

- AI output is treated as a suggestion, not an authoritative decision.
- Commands and configuration are checked against the actual project.
- Secrets and sensitive credentials must not be exposed to AI tools.
- Incorrect suggestions are corrected before implementation.
- Incomplete or untested work is identified honestly.
