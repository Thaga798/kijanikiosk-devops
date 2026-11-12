# Production Security Checklist

This checklist must be reviewed before approving a production deployment.

## Deployment checks

- [ ] Staging deployment completed successfully.
- [ ] Staging rollout completed with all replicas available.
- [ ] Staging health endpoint returned HTTP 200.
- [ ] Production image tag and version were verified.
- [ ] Production resource requests and limits were reviewed.

## Security checks

- [ ] No real passwords, tokens or credentials are committed to Git.
- [ ] Kubernetes Secrets are used for sensitive configuration.
- [ ] Production credentials are managed outside source control.
- [ ] Application runs as a non-root user.
- [ ] Container image and dependencies have been reviewed.
- [ ] Production access is restricted to authorized operators.

## Approval record

- Reviewer:
- Date:
- Decision:
- Reason:
- Jenkins build number:

## Outstanding limitations

The current database connection values and passwords are placeholders.
No production database is provisioned by this project.
The checklist must be completed by a human reviewer before deployment.
