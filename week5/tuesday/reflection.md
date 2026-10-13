# Tuesday Reflection Questions

## Question 1: What the Red Build Proved

In Build #15, the Build stage passed, but the
Test stage failed. This showed that the build
command worked, but the tests found a problem.

The command `npm run build` completed successfully.
However, `npm test` returned exit code 1 because
the test failed. Jenkins detected the failure
and marked the pipeline as failed.

The Archive stage was skipped because the
pipeline did not reach it after the test failure.
This helped prevent a failed build from being
treated as a successful result.

The post-failure actions still ran, which showed
that Jenkins could handle the failure and report
it correctly.

If I introduced a syntax error that stopped the
test runner from starting, the pipeline would
still fail. The console output would help me
identify the cause. Also, `allowEmptyResults: true`
in the JUnit publishing step allows Jenkins to
continue if no test report was created.
This makes the failure easier to investigate
without causing another error during reporting.

## Question 2: npm ci vs npm install in a Team Context

Imagine four developers are working on
KijaniKiosk. Their `package.json` allows a range
of versions for a dependency such as Express.

The pipeline passes on Monday, but a new
dependency version is released later that day.
If the team uses `npm install`, the next build
may resolve a different version. This could
cause unexpected problems even if nobody
changed the application code.

Using `npm ci` helps avoid this problem.
It installs the dependency versions recorded
in `package-lock.json` and starts with a clean
`node_modules` directory.

This makes builds more consistent between
developers' machines and Jenkins. It also
helps the team find out whether a failure
comes from a code change or a change in the
dependencies.

For CI pipelines, I would use `npm ci` when
the project has a valid lockfile. Developers
should update dependencies deliberately and
commit the updated lockfile so everyone uses
the same dependency versions.

## Question 3: The Archived Artifact (Looking Ahead)

Keeping every build artifact on the Jenkins
server can eventually use too much disk space.
A tool such as Nexus can help by storing
artifacts in a central location.

The team should have a retention policy that
removes old development builds after a set
period or keeps only a chosen number of builds.
For example, it could keep the latest ten
development builds. Important release artifacts
could follow a separate retention policy.

A central artifact store also makes it easier
to share build outputs with other environments.
Instead of rebuilding the application on every
machine, another pipeline can download the
artifact that was already tested.

For example, a deployment job could download
an artifact using `curl` or `wget` from a
secured repository URL.

This would make deployments more consistent
because the team can promote the same tested
artifact between environments. Access controls
and backups would also be important to protect
the stored files and keep them available when
needed.

## Question 4: What Tuesday's Pipeline Still Cannot Do

The current pipeline cannot reliably detect
known security vulnerabilities in dependencies.
It mainly checks whether the application builds
and whether its tests pass. A vulnerable package
could still pass both checks.

One improvement would be to add a Security Scan
stage that runs `npm audit`. This checks the
project's dependencies against known vulnerability
information. The team can decide which findings
should fail the build based on their severity
and the project's risk.

Another option is Software Composition Analysis
using a tool such as Snyk. It can help identify
vulnerable third-party packages.

I would also consider adding a static analysis
tool such as Semgrep. It checks the application's
source code for potentially unsafe coding
patterns.

These checks should run before the artifact is
archived and considered ready for deployment.
They will not catch every possible security
problem, but they add useful checks that the
current pipeline does not provide.
