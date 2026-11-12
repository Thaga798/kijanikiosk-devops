# KijaniKiosk Capstone Architecture

## Overview

The application is packaged as a container and deployed to Kubernetes.
NGINX Ingress routes external HTTP traffic to the payments Service.
Separate namespaces and configuration provide staging and production
environment separation.

## Architecture diagram

```mermaid
flowchart TD
    U[External User] --> I[NGINX Ingress]
    I --> S[Payments ClusterIP Service]
    S --> P[Production Deployment]
    P --> PP[3 Payments Pods]

    J[Jenkins Pipeline] --> ST[Staging Namespace]
    ST --> SD[Staging Deployment]
    SD --> SP[Staging Pods]

    J -->|Smoke test passes| A{Human Approval}
    A -->|Approved| P
    A -->|Rejected| X[Stop Deployment]

    C[ConfigMaps and Secrets] --> P
    C --> SD

    M[Ingress Access Logs] --> E[Error Rate Monitor]
    E --> R[5xx Error Rate Report]

## Main components

- NGINX Ingress Controller: receives HTTP traffic and routes requests.
- Payments Service: exposes the application internally through ClusterIP.
- Kubernetes Deployments: maintain application replicas.
- Readiness and liveness probes: check application health.
- ConfigMaps and Secrets: separate environment configuration.
- Resource requests and limits: define container resource boundaries.
- Jenkins: proposed staging-to-production deployment workflow.
- Error-rate script: calculates HTTP 5xx percentage from Ingress logs.

## Environment separation

- Production runs in the `default` namespace.
- Staging runs in the `kijani-staging` namespace.
- Each namespace has its own ConfigMap and Secret.

## Traffic flow

External requests reach the NGINX Ingress Controller using the
`kijani.local` host and `/payments` path. Ingress forwards requests
to the payments ClusterIP Service, which selects healthy application Pods.
