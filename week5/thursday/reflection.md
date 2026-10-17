# Week 5 Reflection Questions — KijaniKiosk

## Question 1: Docker Agent Isolation in Depth

I would consider three approaches, starting with the quickest and ending with the most
maintainable option for production.

**Approach 1: Mount a volume using the Docker agent args.**

I could install the required library on the host and mount its directory into the agent
container by updating the Jenkinsfile:

    args '-v /opt/native-libs:/opt/native-libs --network kijanikiosk-ci'

The advantage is that I would not need to rebuild the Docker image immediately.
However, this depends on the host already having the correct library and its dependencies.
It can also cause compatibility problems because Alpine uses musl instead of glibc.

**Approach 2: Use a different base image.**

I could change the Dockerfile base image from `node:18-alpine` to `node:18-bookworm-slim`
and install the required packages using `apt-get`. This Debian-based image may be easier
to work with if the dependency expects a glibc-based Linux environment. The disadvantage
is that the image may be larger and the change would need compatibility testing.

**Approach 3: Build and maintain a custom Docker image.**

I could update the existing Dockerfile to install the required `libvips` packages,
then rebuild and version the agent image. Jenkins would continue using that declared image.
This is maintainable because the dependency setup can be reviewed and reproduced.
The disadvantage is that image changes take time to build, test, and maintain.


## Question 2: Parallel Stage Design Decisions

The current Verify stage runs the Test and Security Audit branches in parallel, so they
can finish without waiting for each other. Adding an integration test that takes eight
minutes could push verification close to, or beyond, the ten-minute limit when setup,
database startup, and other checks are included. Parallel execution does not guarantee
that the whole stage will finish within the required time.

I would keep the main pipeline focused on fast feedback from linting, building, unit tests,
and dependency auditing. I would move the database integration tests into a separate
Jenkins pipeline or downstream job with its own database setup, timeout, and resource limits.

A suitable Jenkins mechanism is a separate downstream job triggered after the main pipeline
succeeds. For example, the main Jenkinsfile could use a `post { success { ... } }` action
to trigger the integration-test job without waiting for it to finish. This lets developers
receive the fast pipeline result first while the longer checks continue independently.
The integration-test result would still need to be monitored before release or deployment.


## Question 3: The Week as a Complete System

### A. Plain-language explanation for Nia

When a developer submits code changes, our automated system checks whether the changes
are ready to move forward. It first checks the code for basic quality problems, then builds
the application and runs its tests. It also checks the project's dependencies for known
security vulnerabilities.

If a required check fails, the system stops the later steps instead of publishing a package
that has failed verification. When
cat > week5/thursday/reflection.md <<'EOF'
# Week 5 Reflection Questions — KijaniKiosk

## Question 1: Docker Agent Isolation in Depth

I would consider three approaches, starting with the quickest and ending with the most
maintainable option for production.

**Approach 1: Mount a volume using the Docker agent args.**

I could install the required library on the host and mount its directory into the agent
container by updating the Jenkinsfile:

    args '-v /opt/native-libs:/opt/native-libs --network kijanikiosk-ci'

The advantage is that I would not need to rebuild the Docker image immediately.
However, this depends on the host already having the correct library and its dependencies.
It can also cause compatibility problems because Alpine uses musl instead of glibc.

**Approach 2: Use a different base image.**

I could change the Dockerfile base image from `node:18-alpine` to `node:18-bookworm-slim`
and install the required packages using `apt-get`. This Debian-based image may be easier
to work with if the dependency expects a glibc-based Linux environment. The disadvantage
is that the image may be larger and the change would need compatibility testing.

**Approach 3: Build and maintain a custom Docker image.**

I could update the existing Dockerfile to install the required `libvips` packages,
then rebuild and version the agent image. Jenkins would continue using that declared image.
This is maintainable because the dependency setup can be reviewed and reproduced.
The disadvantage is that image changes take time to build, test, and maintain.


## Question 2: Parallel Stage Design Decisions

The current Verify stage runs the Test and Security Audit branches in parallel, so they
can finish without waiting for each other. Adding an integration test that takes eight
minutes could push verification close to, or beyond, the ten-minute limit when setup,
database startup, and other checks are included. Parallel execution does not guarantee
that the whole stage will finish within the required time.

I would keep the main pipeline focused on fast feedback from linting, building, unit tests,
and dependency auditing. I would move the database integration tests into a separate
Jenkins pipeline or downstream job with its own database setup, timeout, and resource limits.

A suitable Jenkins mechanism is a separate downstream job triggered after the main pipeline
succeeds. For example, the main Jenkinsfile could use a `post { success { ... } }` action
to trigger the integration-test job without waiting for it to finish. This lets developers
receive the fast pipeline result first while the longer checks continue independently.
The integration-test result would still need to be monitored before release or deployment.


## Question 3: The Week as a Complete System

### A. Plain-language explanation for Nia

When a developer submits code changes, our automated system checks whether the changes
are ready to move forward. It first checks the code for basic quality problems, then builds
the application and runs its tests. It also checks the project's dependencies for known
security vulnerabilities.

If a required check fails, the system stops the later steps instead of publishing a package
that has failed verification. When the checks pass, it saves the built application and gives
it a version linked to the code change that produced it. The package is then sent to our
internal package registry, where the team can retrieve the exact version later.

We have also tested deliberate failures to check that the system responds correctly.
The result is a more repeatable process with clearer feedback and fewer manual steps.
A successful run means the package passed the checks we configured; it does not mean
that every possible problem has been ruled out or that the application is already deployed.


### B. Technical explanation for Tendo

A Git commit on `feature/week5-docker-agent` triggers the Jenkins job
`kijanikiosk-payments`. Jenkins checks out the source and runs the stages inside the
`kijanikiosk-node18-agent:1.0` Docker image on the `kijanikiosk-ci` network.

Initialize Metadata reads the package version and short Git revision and derives a
versioned identifier for the package. Lint installs dependencies and runs the lint script.
Build installs dependencies, runs the build script, verifies the `dist` output, and stashes
the build output for downstream use.

Verify executes Test and Security Audit in parallel. Test unstashes the build output,
runs the test suite, and records JUnit results. Security Audit runs `npm audit` with the
configured high-severity threshold. If a required stage fails, dependent stages are skipped.

Archive stores the build outputs in Jenkins and fingerprints the archived artifacts.
Publish retrieves the `nexus-credentials` credential through `withCredentials`, prepares
the package version, and publishes it to the Nexus npm repository at
`http://nexus:8081/repository/npm-kijanikiosk/`. The pipeline reports success or failure
and performs workspace cleanup. A successful build confirms publication, not deployment.


### C. What is the same and what is different?

Both explanations describe the same sequence: code is submitted, automated checks run,
a versioned package is archived, and a successful package is published to Nexus.
Both also explain that failures should stop the package from progressing through later
stages.

The difference is the level of detail. Nia's explanation focuses on the business value:
repeatability, early feedback, traceability, and reduced manual work. Tendo's explanation
names the Jenkins stages, Docker image, Git revision, test and audit commands, credential
handling, artifact archiving, and Nexus destination. The technical explanation is useful
for troubleshooting and implementation, while the plain-language version is suitable
for explaining the system's purpose and limits to a non-technical audience.


## Question 4: What the Pipeline Cannot Prevent

One category is **business logic errors that the current tests do not cover**. The application
could pass its existing tests but still calculate a payment incorrectly for an unusual
transaction or handle a real customer scenario badly. A green test result only confirms
that the checks written so far passed. Code review, exploratory testing, and user acceptance
testing can help identify missing requirements and unexpected behaviour. These checks need
human judgement and realistic scenarios that may not be practical to include in every
fast pipeline run.

A second category is **problems that appear only in a production-like environment**.
For example, the application might perform poorly under heavy traffic or fail when it
interacts with a real database or an external service. Unit tests and dependency auditing
cannot fully reproduce those conditions. Load testing, staging integration tests, and
release-readiness reviews can identify these risks. Some integration checks can run in CI,
but resource-intensive tests may belong in a separate stage or pre-release process to
avoid slowing down every code change. Neither category is guaranteed to be caught, so a
green pipeline should be treated as evidence of passed checks, not proof of zero defects.
