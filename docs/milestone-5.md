# Milestone 5 — ECR and ECS/Fargate

## Implementation

A shared platform module configures dev and prod:
- Immutable-tag, encrypted ECR repositories with scan-on-push enabled.
- ECS clusters and scoped execution roles.
- CloudWatch application logs: dev 7 days, prod 30 days.
- Private Fargate services: dev 1 task, prod 2 tasks.
- Digest-pinned images with Git SHA application versions.
- Non-root containers, read-only root filesystems and dropped capabilities.
- Container health checks and deployment circuit breaker.

The application needs no AWS permissions and has no task role.

## Validation

Dev application logs confirm startup on port 8000 and repeated
/health responses with HTTP 200.

Service counts and completed rollout were checked by the operator.
Detailed command evidence is retained under docs/evidence/.

## Remaining limitations

Prod remains unapplied.
External ALB access and HTTPS are pending Milestone 6.
ECR scanning is enabled, but scan findings have not yet been reviewed.
