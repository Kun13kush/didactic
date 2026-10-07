# Milestone 7 — IAM and GitHub OIDC

## Implementation

Existing GitHub OIDC provider reused.
Trust restricted to the immutable identity of Kun13kush/didactic
and the corresponding dev or production GitHub environment.

Separate deployment roles have scoped ECR, ECS and PassRole permissions.
They cannot manage IAM, networking or Terraform state.
GitHub authentication uses temporary credentials, not stored AWS keys.

## Validation

Both environment-scoped OIDC authentication runs were reported successful.
The dev PassRole simulation allowed the dev execution role and denied
the production execution role.

The OIDC check workflow does not deploy application resources.

## GitHub controls

Dev allows develop; production allows main.
Production requires manual approval and administrator bypass is disabled.

The operator is the sole production reviewer. This is a manual gate,
not independent review.

Branch protection and full CI/CD deployment tests remain pending.
Production application infrastructure remains unapplied.
