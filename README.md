# KijaniKiosk Container Delivery Capstone

## 1. About the project

This is my DevOps capstone project for the KijaniKiosk payments application. The main goal was to take an application I had been working on and put together a more complete container delivery and Kubernetes deployment workflow.

During the project, I worked on building a production container image, deploying the application to separate staging and production environments, configuring health checks, setting up ingress routing and testing how Kubernetes responds when a Pod fails.

I also worked on a Jenkins pipeline to automate the deployment process. The pipeline includes a staging deployment, a health check and a manual approval step before production deployment.

This project helped me connect several of the topics I had covered during the course and understand how they work together in a practical environment.

## 2. Where to find the project on GitHub

The capstone is part of my KijaniKiosk DevOps repository.

- **GitHub repository:** https://github.com/Thaga798/kijanikiosk-devops
- **Capstone project folder:** https://github.com/Thaga798/kijanikiosk-devops/tree/feature/capstone-infrastructure/capstone
- **Working branch:** `feature/capstone-infrastructure`

The capstone files are inside the `capstone/` directory. The project includes the application, Kubernetes manifests, Jenkins pipeline, scripts, documentation and test evidence.

## 3. Architecture and tools used

The application runs in a local Kubernetes cluster managed by Minikube. I used two namespaces to separate the environments:

- `default` – production environment.
- `kijani-staging` – staging environment.

Both environments use the same Kubernetes Deployment and Service definitions, with environment configuration applied separately. Each Deployment maintains three replicas of the payments application.

NGINX Ingress handles external HTTP traffic for `kijani.local/payments` and forwards requests to the payments Service. The application exposes a health endpoint at `/health`.

The main tools used were:

- **Docker** – building and running the application container.
- **Kubernetes and Minikube** – managing the staging and production deployments.
- **Jenkins** – automating the deployment and approval workflow.
- **kubectl** – applying manifests and checking cluster resources.
- **NGINX Ingress** – routing incoming application traffic.
- **Bash** – implementing the error-rate monitoring script.
- **Git and GitHub** – tracking changes and storing the project.

The architecture documentation is available in `capstone/docs/architecture.md`.

## 4. Setting up the project

The following steps describe how to run the application in a local environment.

### Prerequisites

You need:

- Linux
- Git
- Docker
- kubectl
- Minikube with the Docker driver

Jenkins with Pipeline support is additionally required if you want to run the automated deployment workflow.

### Clone the repository

```bash
git clone --branch feature/capstone-infrastructure \
  https://github.com/Thaga798/kijanikiosk-devops.git

cd kijanikiosk-devops
```

### Start Minikube

For a fresh local setup, start the cluster with:

```bash
minikube start -p capstone --driver=docker --memory=2048 --cpus=2

kubectl config use-context capstone
```

Enable the NGINX Ingress addon:

```bash
minikube addons enable ingress -p capstone
```

### Initial namespace and configuration setup

These commands are for initial setup on a fresh cluster. The Jenkins pipeline handles the subsequent staging and production deployments.

```bash
kubectl apply -f capstone/k8s/staging-namespace.yaml

kubectl apply -f capstone/k8s/environment-config.yaml
```

The environment configuration contains the ConfigMaps and demonstration Secrets used by the two environments.

### Build and load the application image

```bash
docker build --build-arg APP_VERSION=1.0.0-capstone \
  -t kijanikiosk/kk-payments:1.0.0-capstone \
  -f capstone/app/Dockerfile.production capstone/app
```

Load the image into Minikube:

```bash
minikube image load kijanikiosk/kk-payments:1.0.0-capstone -p capstone
```

The Deployment uses `imagePullPolicy: Never`, so the image must be available inside the Minikube node before deployment.

### Deploy to production

```bash
kubectl apply -n default -f capstone/k8s/production-service.yaml

kubectl apply -n default -f capstone/k8s/production-deployment.yaml

kubectl apply -n default -f capstone/k8s/ingress.yaml
```

### Deploy to staging

```bash
kubectl apply -n kijani-staging -f capstone/k8s/production-service.yaml

kubectl apply -n kijani-staging -f capstone/k8s/production-deployment.yaml
```

Check that the deployments are ready:

```bash
kubectl get deployments -n default

kubectl get deployments -n kijani-staging
```

## 5. Jenkins deployment pipeline

The pipeline is defined in `capstone/Jenkinsfile`. I configured a separate Jenkins job called `kijanikiosk-capstone` so that the earlier coursework Jenkins job could remain unchanged.

The pipeline follows these stages:

1. Checks out the capstone branch and validates the required files.
2. Checks access to the Kubernetes cluster.
3. Applies the application configuration and deploys to staging.
4. Waits for the staging Deployment rollout.
5. Runs a staging health check.
6. Presents a production security review.
7. Requests human approval and records the approver and reason.
8. Deploys to production after approval.
9. Runs a production health check.

The Jenkins agent uses a dedicated Kubernetes service account with permissions scoped to the application namespaces.

### Successful pipeline run

The pipeline was successfully executed in Jenkins.

- **Jenkins job:** `kijanikiosk-capstone`
- **Successful build:** `#6`
- **Branch:** `feature/capstone-infrastructure`
- **Result:** SUCCESS

Both staging and production returned a successful health response:

```json
{
  "status": "ok",
  "version": "1.0.0-capstone",
  "port": 3001
}
```

The production approval was completed by the Jenkins user recorded as `ED04`. The approval reason was:

> Staging smoke test passed; security review completed.

The pipeline run and screenshots are saved in `capstone/evidence/`.

One current limitation is that the pipeline was started manually from the capstone Jenkins job. Automatic triggering on a merge to the `main` branch has not been configured. The application image is also built and loaded into Minikube separately rather than built by Jenkins.

## 6. Testing and monitoring

I tested the application and deployment at different stages of the project.

### Kubernetes deployment checks

I verified that both environments had three ready application replicas. I also tested Kubernetes self-healing by deleting a running Pod and observing the controller create a replacement.

### Application health checks

The application exposes a `/health` endpoint. I used it to check that the application was responding in both environments.

The Jenkins pipeline also runs health checks after the staging and production deployments.

### Ingress test

The application can be tested through the local ingress route:

```bash
curl -i -H "Host: kijani.local" \
  "http://$(minikube ip -p capstone)/payments/"
```

### Error-rate monitoring

I created `capstone/scripts/check-error-rate.sh` to inspect NGINX Ingress logs for HTTP 5xx responses.

The script uses a default error threshold of 5% over a two-minute window. I tested it with successful requests and a sample containing server errors to confirm that it detects an increased error rate.

This is a manual monitoring script, not a continuously running Prometheus alerting setup.

Additional verification records are available in `capstone/evidence/`.

## 7. Project structure

```text
capstone/
├── app/
│   ├── .dockerignore
│   ├── Dockerfile.production
│   ├── package.json
│   └── server.js
├── docs/
│   ├── ai-governance-log.md
│   ├── approval-audit.md
│   ├── architecture.md
│   ├── production-security-checklist.md
│   ├── project-scope.md
│   └── reflection.md
├── evidence/
│   ├── error-rate-monitor-test.txt
│   ├── final-deployment-verification.txt
│   ├── jenkins-pipeline-success.txt
│   ├── kubernetes-verification.txt
│   ├── production approval.png
│   ├── production smoke test.png
│   ├── smoke test.png
│   └── stage view.png
├── k8s/
│   ├── environment-config.yaml
│   ├── ingress.yaml
│   ├── production-deployment.yaml
│   ├── production-service.yaml
│   └── staging-namespace.yaml
├── scripts/
│   └── check-error-rate.sh
└── Jenkinsfile
```

## 8. Current limitations and next improvements

There are still parts of the larger capstone requirements that I would improve before treating this as a fully production-ready system.

- Terraform and Ansible provisioning of the environments has not been implemented as part of this capstone.
- Jenkins does not yet trigger automatically when changes are merged into `main`.
- The container image is built and loaded separately; image building and publishing are not yet part of the Jenkins pipeline.
- The monitoring script is manual. Prometheus alert rules and continuous alerting have not been configured.
- Real staging and production databases have not been provisioned. The current Secrets contain demonstration configuration, not production credentials.
- The serverless receipt-processing integration has not been completed.
- Peer testing and feedback have not been completed.

These are areas I would work on next. The project currently demonstrates containerisation, Kubernetes deployments, environment separation, health checks, basic monitoring and an approval-controlled Jenkins deployment workflow, but it should not be considered a complete production implementation.

Overall, this capstone gave me a better understanding of how application deployment, infrastructure, automation and monitoring fit together in DevOps.
