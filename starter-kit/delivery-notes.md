# DevOps Delivery Notes - KijaniKiosk

## 1. DevOps Mindset

The KijaniKiosk project applies the three core DevOps principles of Flow, Feedback, and Learning.

### Flow

Work is divided into small, manageable changes rather than making large changes at once. Git feature branches are used to isolate individual tasks, allowing development work to move from implementation to review and integration in a controlled way.

The workflow is:

1. Create a feature branch from `develop`.
2. Implement one focused change.
3. Commit the change with a clear message.
4. Push the branch to GitHub.
5. Create a Pull Request.
6. Review and validate the change.
7. Merge the approved change into `develop`.

This approach reduces the risk of introducing several unrelated changes at the same time.

### Feedback

Feedback is collected through Pull Requests, code review, testing, and CI/CD validation. A change should not be considered complete simply because it works on the developer's machine.

Feedback helps identify:

- Configuration mistakes
- Security issues
- Incorrect assumptions
- Failed tests
- Infrastructure problems
- Opportunities to improve documentation

The Pull Request process provides a clear point where feedback can be received before changes become part of the shared development branch.

### Learning

DevOps requires continuous learning from both successful and unsuccessful changes. When a command fails, a deployment does not behave as expected, or a configuration causes an unexpected result, the issue should be investigated and documented instead of simply being worked around.

The project therefore treats errors and feedback as opportunities to improve future implementation. Lessons learned from infrastructure, security, Git workflows, and automation can be applied to subsequent tasks.

## 2. Reflection

### Where was I tempted to shortcut the process?

A common temptation is to make changes directly on the main development branch because it appears faster. However, using feature branches and Pull Requests provides better traceability and creates an opportunity for review before integration.

### Which architecture decision required the most reasoning?

The network architecture required careful consideration because public and private resources should not have the same level of internet exposure. The design therefore separates public-facing resources from private application resources and controls communication through routing and security rules.

### If the platform grows significantly, what would I improve first?

As KijaniKiosk grows, I would first improve automation and reliability. Infrastructure provisioning, testing, security checks, monitoring, and deployments should become increasingly automated so that the platform can scale without relying on manual administration.

## 3. Key DevOps Lessons

- Keep changes small and traceable.
- Use Git branches for isolated work.
- Use Pull Requests to obtain feedback.
- Automate repetitive validation and deployment tasks.
- Treat failures as learning opportunities.
- Document important technical and architectural decisions.
- Build security and reliability into the system from the beginning.
