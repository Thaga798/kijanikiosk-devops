# Week 5 Monday Reflection

## Question 1: What Today's Pipeline Does Not Do

The current pipeline mainly checks that the Node.js runtime is available. For example, it can run `node --version`, but this alone is not enough to call it proper Continuous Integration.

The first missing property is **Flow**. The pipeline should automatically build and test the application after a change is pushed. I would add steps such as `npm ci` to install the dependencies and `npm test` to run the project's tests. If the project has a build command, I would also run `npm run build`.

The second property is **Feedback**. Jenkins should clearly report whether the build and tests passed or failed. The pipeline should stop when a command returns an error and show the output in the Jenkins console.

The third property is **Learning**. Test results and build failures should be kept as pipeline results or artifacts so the team can see what went wrong and use that information to improve future changes.

## Question 2: The Broken-Build Contract in Practice

A developer could argue for an exception if they are working on an important feature that has to be demonstrated soon. For example, they might say that fixing the broken main branch can wait until they finish their feature because the board review is only three weeks away.

The problem is that the broken build affects everyone, not just that developer. Other developers may push changes that cannot be properly tested or integrated because the shared pipeline is already failing. This makes it harder to know whether a new failure was caused by their work or the existing problem.

If the team allows "just this once" exceptions, they can quickly become normal practice. During a two-week sprint, several developers might continue working while the build is broken. By the time someone finally fixes it, there may be many changes to investigate at once. Fixing the build early keeps the problem small and protects the team's feedback loop.

## Question 3: The Jenkinsfile in the Repository

Keeping the Jenkinsfile only in the Jenkins UI creates a few practical problems. First, if the Jenkins server is rebuilt after a failure, the pipeline configuration can be lost unless it was backed up separately. The repository version is much easier to restore because the Jenkinsfile is stored together with the application code.

Second, developers cannot easily see how the pipeline works if its definition is hidden inside Jenkins. Someone investigating a failed build would have to open the Jenkins configuration instead of simply checking the repository.

It also makes code review harder. For example, if I change a command from `npm test` to `npm run test:ci`, that change should be visible in Git and reviewed like other code changes. With a Jenkinsfile, the pipeline can be committed to a branch, reviewed through a Pull Request, and tracked in Git history. This makes the CI configuration easier to understand, reproduce, and maintain.

## Question 4: Webhooks vs Polling

For this setup, SCM polling can be used to check the Git repository for new commits. Jenkins periodically contacts the repository and compares the latest commit with the commit it previously built. If a change is found, Jenkins starts a new build. For example, polling every five minutes means Jenkins may take up to five minutes to notice a new push.

A webhook would be more appropriate when the team needs faster feedback. With a webhook, GitHub sends a request directly to Jenkins when a push occurs, so Jenkins can start the pipeline almost immediately instead of waiting for the next polling interval.

Polling is acceptable for a small project with a few developers and relatively few pushes. However, as the team grows, the delay becomes more noticeable. With four developers making several pushes during the day, five-minute delays can slow down testing and feedback. On a larger team with many repositories and frequent pushes, webhooks provide a much faster feedback loop and avoid unnecessary repeated checks.
