# Week 8 Wednesday Reflection: Private Registries

### Question 1: The Semver-SHA Tag and Rollback

To roll back the production deployment, I would first identify the Kubernetes Deployment running the payments application. I would then change the image reference in the Deployment manifest from `1.0.0-d9e1f4a` to `1.0.0-a3f2c8b`. The field that changes is `spec.template.spec.containers[].image`. After saving the manifest, I would apply it using `kubectl apply -f deployment.yaml`. Alternatively, I could use `kubectl set image deployment/kk-payments kk-payments=ghcr.io/thaga798/kk-payments:1.0.0-a3f2c8b` to update the image directly. Kubernetes would then perform a rolling update using the previous image version.

This is similar to the Week 7 rollback because both procedures restore an earlier working application version. However, the Week 7 rollback script switched the nginx upstream to direct traffic to the previous environment, while Kubernetes changes the image used by the Deployment and replaces Pods gradually. Both approaches aim to restore service without rebuilding the application. The main difference is that Kubernetes manages the replacement of application containers through its Deployment controller.

### Question 2: The ImagePullSecret Lifecycle

When the GitHub Personal Access Token expires, I would first generate a replacement token with the required `read:packages` permission. I would then update the existing Kubernetes ImagePullSecret using the new credentials. I could do this by running `kubectl create secret docker-registry kijani-registry-credentials --docker-server=ghcr.io --docker-username=Thaga798 --docker-password="$NEW_TOKEN" --dry-run=client -o yaml | kubectl apply -f -`. After confirming that the secret has been updated, I would revoke the expired token and verify that new Pods can pull the image successfully.

The deployment manifest does not need to change because it references the secret by its name, `kijani-registry-credentials`, rather than containing the actual token. Kubernetes continues using that reference when it needs to pull images. This is similar to Week 5, when the Nexus password was rotated in Jenkins credentials while the Jenkinsfile continued referencing the same `credentialsId`. In both cases, the secret value changes while the application configuration keeps the same reference.

### Question 3: The Latest Tag in CI Pipelines

I would not recommend using `latest` as the image reference for production deployments because it is a mutable tag. Different builds can overwrite it, making it difficult to identify exactly which application version is running. During a Kubernetes rolling update, different Pods could end up running different image versions if the `latest` tag changes while the rollout is taking place. This can cause inconsistent application behaviour and make troubleshooting or rollback more difficult.

The safer approach is to deploy using immutable versioned tags that combine the semantic version and Git commit SHA. This identifies the exact build being deployed. However, a CI pipeline can still publish a `latest` tag as an additional convenience for development or testing. The important precaution is to ensure production manifests use the exact versioned tag or image digest rather than `latest`. This preserves traceability and makes deployments predictable.

### Question 4: Registry, Nexus, and the Delivery Pipeline

Nexus and the container registry serve different purposes in the delivery pipeline. Nexus stores npm packages as tarball artifacts, while the container registry stores complete Docker images that include the application and its runtime dependencies. During the multi-stage Docker build, the builder stage retrieves the required npm packages, installs dependencies and prepares the application. The production stage then copies only the required application files and production dependencies into the final image.

When npm packages are installed, their tarballs are normally unpacked into `node_modules`. The tarball itself is not normally copied into the final production image. Instead, the resulting application and required dependencies become part of the container image. The Docker image therefore becomes the deployable application artifact for Kubernetes, but this does not make Nexus irrelevant. Nexus continues to provide a central location for storing and distributing reusable npm packages. The container registry complements Nexus by storing the finished application image that is deployed to the cluster.
