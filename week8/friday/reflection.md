# Week 8 Friday Project Reflection

## 1. Hardest pipeline step to automate reliably

The hardest step to automate reliably is coordinating the transition from
building an application image to publishing and deploying that exact image.
Extending the Week 5 Jenkins pipeline requires more than adding another build
stage. The pipeline must generate a consistent version, authenticate with
the private registry, publish the image, and ensure Kubernetes deploys the
same image that was built.

A major failure mode is a mismatch between the image tag generated during
the build and the tag referenced by the deployment configuration. Registry
authentication and network connectivity can also interrupt the process.
During the earlier Jenkins and Nexus work, connectivity and DNS resolution
were practical issues, demonstrating why each stage needs clear failure
handling and verification.

My approach is to generate the version from the package version and the Git
commit SHA, then reuse that exact value throughout the publishing and
deployment process. This reduces manual versioning errors and makes it
easier to trace a deployed image back to its source commit. The final
implementation still needs to demonstrate a successful push, fresh pull,
and Kubernetes deployment.

## 2. Rewriting Nia's explanation for Tendo

A plain-language explanation of the deployment approach could be:

"The application is packaged once and delivered to the environment where it
will run. If a container fails, Kubernetes can replace it, while additional
copies help the application handle more requests."

A more technical explanation for Tendo would be:

"The application is packaged as a versioned container image and published
to a private registry. Kubernetes retrieves the image using the configured
registry credentials and maintains the desired replica count through its
Deployment controller. A failed Pod is replaced through the controller's
reconciliation process, while horizontal scaling can increase the number
of replicas to distribute workload."

The technical explanation is more precise because it identifies the
container registry, image versioning, authentication, Deployment controller,
and replica management. It also introduces terminology that helps an
engineer investigate and troubleshoot the system.

However, the plain-language explanation is easier for a non-technical
stakeholder to understand. It communicates the operational outcome without
requiring knowledge of Kubernetes terminology. The technical version gains
precision but loses some accessibility. Both explanations are useful,
depending on the audience.

## 3. Hardcoded values and the need for configuration management

The Kubernetes Deployment requires several values that should eventually
be separated from the application deployment definition.

The container image address and version are environment-dependent. Keeping
them directly in the manifest makes promoting an application between
staging and production more difficult and increases the possibility of
deploying an unintended version.

The replica count is also a configuration value. Different environments
may require different numbers of application instances. Keeping the value
fixed in the manifest makes scaling between environments less flexible.

The application port, environment name, and application version are other
values that should be managed consistently. The application version must
agree with the image tag so that health checks and operational logs identify
the running release correctly.

Resource requests and limits may also need environment-specific adjustment.
A configuration suitable for a small testing cluster may not be appropriate
for a production workload.

Registry credentials must not be stored as plain text in the Deployment
manifest or committed to Git. They should be managed through Kubernetes
Secrets or an appropriate external secret-management solution. The
deployment should refer to the registry credential object without exposing
its contents.

In Week 9, ConfigMaps can be used for non-sensitive configuration, while
Secrets can hold sensitive values such as credentials. Separating these
values improves portability, reduces accidental exposure, and makes
environment-specific changes easier to manage.

## 4. Overall reflection

This project brings together containerisation, private image distribution,
and Kubernetes deployment. The main lesson is that a working application
image is only one part of a delivery process. Reliable delivery also
requires consistent versioning, secure authentication, repeatable deployment
configuration, and evidence that the application is reachable after
deployment.

The next step is to complete the implementation and verify each stage
independently before treating the pipeline as successful. The final
submission should include the actual image build results, registry
verification, Kubernetes deployment output, Service checks, and measured
self-healing behaviour.
