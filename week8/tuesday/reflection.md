# Week 8 Tuesday Reflection

## 1. Docker Layer Optimisation

Docker images are built in layers. If dependencies or build tools are installed in one
layer and deleted in a later layer, deleting them does not remove their data from the
earlier immutable layer. The deletion only hides the files in the final filesystem.
This means the image can remain large even after cleanup.

A multi-stage build solves this by keeping build tools in the builder stage and copying
only the required production files into the final stage. This keeps unnecessary build
dependencies out of the production image.

## 2. HEALTHCHECK and Application Startup

The HEALTHCHECK uses a 15-second start period, a 30-second interval, a 3-second
timeout and three retries. If an application takes 25 seconds to start, a failed check
during the first 15 seconds is ignored for the failure count. A failed check after the
start period counts, but the application should become ready around 25 seconds.
The next check around 30 seconds should succeed and reset the failure streak.

The container is marked unhealthy only after three consecutive counted failures.
In Kubernetes, I would also configure a readiness probe for the application's health
endpoint. Docker HEALTHCHECK status alone does not control Kubernetes service traffic.

## 3. Non-Root Security

Running the payments application as a non-root user reduces the damage an attacker
could cause if the application were compromised. A root process could modify
system files, install software or access resources beyond the application's needs.
A non-root process has fewer permissions, limiting its potential impact.

The Dockerfile creates the kijani user and changes ownership of the application
directory before switching to that user. This ensures the application can access
its files after privileges are dropped. In a larger production system, ownership
should be limited to the directories the application actually needs to write to.

## 4. Builder Stage in a Jenkins Pipeline

Jenkins can first build the builder stage using the Dockerfile's builder target.
It can then run the application's tests inside that image. If the tests pass, Jenkins
can build the final production image, tag it with the build version and push it to
the container registry using credentials stored securely in Jenkins.

This project starter currently defines only start and build scripts. It has no test
script, Jest package or TypeScript development dependency, so an automated test
suite could not be demonstrated without adding tests to the application.

## Verification Notes

The production image built successfully and ran as the non-root kijani user.
The TypeScript compiler and TypeScript package were absent from the production
image. The container became healthy on the second health check.

The image size reported by Docker was 181MB, which is above the 100MB target.
The size requirement therefore remains unmet. The current starter has no
development dependencies to remove, limiting the size reduction possible through
multi-stage dependency separation.
