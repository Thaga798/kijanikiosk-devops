# Week 5 Wednesday Reflection Questions

## Question 1: Artifact Versioning Under Real Team Conditions

In our KijaniKiosk project, we combined the version in package.json with the Git short SHA to create unique artifact versions. Suppose Developer A
merges a feature with commit a3f2c8b while Developer B merges another feature with commit b7d9e2a.

Developer A's build produces version 1.0.0-a3f2c8b, while Developer B's build produces 1.0.0-b7d9e2a. Although both artifacts use the same package
version, their complete version strings differ because their commits have different SHAs. Therefore, both can exist in Nexus without conflicting.

If Disable redeploy is enabled, Developer A can publish 1.0.0-a3f2c8b, and Developer B can publish 1.0.0-b7d9e2a because it is a different version.
The setting prevents overwriting an existing version, not publishing new versions. In our actual Build #52, Jenkins successfully published
kijanikiosk-payments version 1.0.0-403f9af. This demonstrated how Git-based versioning improves traceability and reduces accidental artifact
replacement when developers merge changes concurrently.

## Question 2: The withCredentials Masking Limit

During our KijaniKiosk lab, we configured Jenkins to retrieve Nexus credentials using the credential ID nexus-credentials. Our Publish stage used
withCredentials to expose the password temporarily through the NEXUS_PASS environment variable. Build #52 displayed a masking notice, and
publishing completed successfully.

However, masking does not guarantee that every transformed version of a secret will be hidden. For example, if a script converts the Nexus
password into Base64 and prints the encoded value, Jenkins may not recognise it as the original secret. The encoded string differs from the stored
password, so it could appear unmasked in the console.

The defence is to avoid printing credentials or transformed secrets. In our pipeline, we used set +x to disable shell command tracing before
handling credentials. We also created a temporary .npmrc file for authentication and configured an EXIT trap to remove it. These protections
belong inside the Publish stage, around the commands that handle credentials. Passwords and encoded secrets should never appear in debugging
output or build logs.

## Question 3: The Immutability Requirement

Nexus release repositories should prevent published versions from being overwritten. For example, suppose our KijaniKiosk pipeline publishes
version 1.2.3 and the deployment team successfully deploys it to production. Later, another developer accidentally publishes different code using
the same version number.

If redeployment is allowed, the artifact at the existing download path could be replaced while retaining version 1.2.3. A deployment pipeline
might then download different code without recognising that the artifact has changed. This creates a serious problem because the version no
longer guarantees the original artifact contents.

Even rolling back to version 1.2.3 could retrieve the newer, faulty artifact instead of the previously tested release. When multiple teams share
the same registry, one team's accidental overwrite could disrupt another team's deployment or rollback.

During our lab, Jenkins published kijanikiosk-payments version 1.0.0-403f9af to Nexus. In production, disabling redeployment protects that
release from replacement and makes deployments more predictable. Every new release should receive a new version so the team can trace the
deployed artifact to its original build and source commit.

## Question 4: Credential Rotation

In our KijaniKiosk pipeline, the Jenkinsfile refers to the Jenkins credential ID nexus-credentials rather than storing the Nexus password directly.
When the password expires or requires rotation, an authorised administrator first changes or resets the relevant password in Nexus. They then
update the password stored in Jenkins under the existing nexus-credentials entry.

The credential ID and compatible username-and-password configuration remain unchanged. After updating the secret, the administrator runs the
publishing pipeline to confirm that Jenkins can authenticate successfully and publish to the correct Nexus repository. They inspect the console
output and verify that the expected artifact appears in Nexus.

If authentication fails, they check the account permissions, stored credential value, and repository access. The Jenkinsfile does not need
modification because it references the credential by ID rather than containing the actual password.

During our lab, we used withCredentials to access the stored credentials during the Publish stage. Keeping authentication details separate from
pipeline code makes rotation easier, reduces unnecessary code changes, and prevents passwords from accidentally entering Git history. It also
allows the team to update credentials without changing the pipeline's logic.

