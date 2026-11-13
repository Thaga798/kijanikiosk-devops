# KijaniKiosk Container Delivery Capstone

## 1. What is this?

This project demonstrates container delivery and Kubernetes deployment
for the KijaniKiosk payments application. It covers environment
separation, health checks, ingress routing, scaling, basic monitoring
and a proposed controlled production deployment workflow.

## 2. Architecture

The application runs in Kubernetes in separate production (`default`)
and staging (`kijani-staging`) namespaces. NGINX Ingress receives
external HTTP traffic for `kijani.local/payments` and forwards it to
the payments ClusterIP Service.

Each Deployment maintains three application replicas with readiness
and liveness probes. Environment-specific ConfigMaps and Secrets
provide separate configuration. CPU and memory requests and limits
define resource boundaries.

See `capstone/docs/architecture.md` for the architecture diagram and
component descriptions.

## 3. Prerequisites

- Linux environment
- Git
- Docker
- kubectl
- Minikube with the Docker driver
- NGINX Ingress addon
- Jenkins with Pipeline support for pipeline execution

## 4. Setup

Clone the repository:

    git clone --branch feature/capstone-infrastructure git@github.com:Thaga798/kijanikiosk-devops.git
    cd kijanikiosk-devops

Start the local Kubernetes cluster:

    minikube start -p capstone --driver=docker --memory=1800 --cpus=2
    kubectl config use-context capstone

Enable NGINX Ingress:

    minikube addons enable ingress -p capstone

Create the staging namespace and environment configuration:

    kubectl apply -f capstone/k8s/staging-namespace.yaml
    kubectl apply -f capstone/k8s/environment-config.yaml

Build the application image from the capstone application directory:

    docker build --build-arg APP_VERSION=1.0.0-capstone \
      -t kijanikiosk/kk-payments:1.0.0-capstone \
      -f capstone/app/Dockerfile.production capstone/app

Load the image into the Minikube profile:

    minikube image load kijanikiosk/kk-payments:1.0.0-capstone -p capstone

The Deployment uses `imagePullPolicy: Never`, so the image must be
loaded into the Minikube node before applying the Deployment.

Apply the production Service, Deployment and Ingress:

    kubectl apply -n default -f capstone/k8s/production-service.yaml
    kubectl apply -n default -f capstone/k8s/production-deployment.yaml
    kubectl apply -n default -f capstone/k8s/ingress.yaml

Apply the Service and Deployment to staging:

    kubectl apply -n kijani-staging -f capstone/k8s/production-service.yaml
    kubectl apply -n kijani-staging -f capstone/k8s/production-deployment.yaml

## 5. How to run pipeline

The `capstone/Jenkinsfile` describes the intended deployment workflow:

1. Check out the repository and validate required files.
2. Deploy the application to staging.
3. Run a staging health check.
4. Present the production security review and human approval steps.
5. Deploy to production after approval.
6. Run a production health check.

The Jenkins agent requires `kubectl`, access to the same Kubernetes
cluster, and appropriate permissions.

The pipeline is currently a draft. It has not been executed or
validated in Jenkins, and automatic triggering on a merge to the
main branch is not configured.

## 6. How to verify

Check Deployments and Pods:

    kubectl get deployments,pods
    kubectl get deployments,pods -n kijani-staging

Check the Service and Ingress:

    kubectl get service kk-payments-service
    kubectl get ingress kijani-ingress

Test the Ingress route:

    curl -i -H "Host: kijani.local" \
      "http://$(minikube ip -p capstone)/payments/"

Check application health:

    kubectl exec deployment/kk-payments -- wget -qO- http://127.0.0.1:3001/health

Run the manual error-rate check:

    ./capstone/scripts/check-error-rate.sh

The monitor analyses HTTP 5xx responses in a default two-minute log
window and uses a 5% threshold. It can also analyse a readable sample
log file using the `LOG_FILE` environment variable.

## 7. Known limitations

- No real staging or production database has been provisioned.
- Database passwords are demonstration placeholders, not real credentials.
- The Jenkins deployment pipeline has not been executed or validated.
- Automatic deployment triggering on merge to the main branch is not configured.
- Error-rate monitoring is manual; continuous alerting is not configured.
- Horizontal Pod Autoscaling has not been configured; scaling was tested manually.
- The serverless receipt-chain integration has not been implemented.
- Terraform and Ansible provisioning are not demonstrated by the current implementation.
- Peer testing and feedback must still be completed and recorded.
- Further production security, credential and deployment validation is required.
