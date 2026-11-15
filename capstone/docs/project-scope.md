# KijaniKiosk Capstone Project Scope

## Project objective

Demonstrate a practical container delivery and Kubernetes deployment
workflow for the KijaniKiosk payments application, with environment
separation, health checks, controlled production approval and basic
operational monitoring.

## Included in scope

1. Containerized Node.js payments application.
2. Kubernetes production and staging namespaces.
3. Environment-specific ConfigMaps and placeholder Secrets.
4. Kubernetes Deployment with three replicas per environment.
5. Readiness and liveness HTTP probes.
6. CPU and memory requests and limits.
7. ClusterIP Service and NGINX Ingress routing.
8. Manual scaling exercise from three to six replicas and back.
9. Shell-based HTTP 5xx error-rate monitor.
10. Jenkins pipeline draft with staging deployment, smoke tests and
    human production approval.
11. Security checklist, approval audit and AI governance documentation.

## Out of scope or incomplete

- No real production or staging database has been provisioned.
- Database passwords are demonstration placeholders, not real credentials.
- The Jenkins deployment pipeline has not been executed or validated.
- Jenkins automatic triggering on merge to the main branch is not configured.
- The error-rate script is manually executed; continuous alerting is not configured.
- Horizontal Pod Autoscaling has not been configured.
- The serverless receipt-chain integration has not been implemented.
- Peer testing and external feedback must still be completed and recorded.

## Success criteria

- Application Pods become Ready in both namespaces.
- Health endpoints return a successful response.
- Ingress routes `/payments` traffic to the application.
- Services use ClusterIP rather than direct external NodePort exposure.
- Manual scaling demonstrates Kubernetes replica management.
- The monitoring script detects a synthetic HTTP 5xx rate above 5%.
- Production deployment is designed to require human approval.

## Implementation environment

The project is developed and tested locally using Docker and Minikube.
The Jenkins pipeline is documented as an intended deployment workflow
and must be tested in a properly configured Jenkins environment.
