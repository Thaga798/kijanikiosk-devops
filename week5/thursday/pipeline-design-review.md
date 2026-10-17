# Pipeline Design Review — KijaniKiosk Payments

## 1. Pipeline Design Principles

### Principle 1: Fail Fast

The pipeline runs Lint before Build so that code-quality problems are detected early. If Lint fails, dependent stages do not proceed. This avoids spending time building or publishing invalid code.

### Principle 2: Separation of Concerns

The pipeline separates metadata initialization, linting, building, verification, archiving, and publishing into distinct stages. Each stage has a clear responsibility, making failures easier to locate and troubleshoot.

### Principle 3: Parallel Execution

The Verify stage runs the Test and Security Audit branches in parallel. This reduces verification time while ensuring that functional tests and dependency security checks are both performed.

### Principle 4: Secure Credential Handling

Nexus credentials are retrieved through Jenkins credentials using the `nexus-credentials` credential ID. The password is exposed through a credential-bound environment variable rather than hardcoded in the Jenkinsfile. Shell tracing is disabled during sensitive operations to reduce the risk of exposing credentials in logs.

### Principle 5: Reproducible and Traceable Artifacts

The pipeline uses a Docker agent image, `kijanikiosk-node18-agent:1.0`, to provide a consistent Node.js build environment. It derives the artifact version from the package version and short Git revision, archives build outputs, and records fingerprints to improve traceability.

## 2. Improvement Implemented

The Verify stage was organized into parallel Test and Security Audit branches. This allows functional testing and dependency auditing to run independently while preserving the pipeline's failure handling. The successful pipeline run confirmed that both verification branches completed before the artifact was archived and published to Nexus.

## 3. Successful Pipeline Evidence

Build #81 completed successfully. The console log showed the Docker agent running, Lint and Build passing, Test and Security Audit completing in parallel, artifacts being archived, credentials being masked, and the versioned package being published to the Nexus npm repository.

## 4. Conclusion

The pipeline applies stage separation, early failure detection, parallel verification, secure credential management, and artifact traceability. These controls make the CI workflow easier to maintain and help prevent unsuccessful builds from being published.
