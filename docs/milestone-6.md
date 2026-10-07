# Milestone 6 — ALB, HTTPS and health checks

## Implementation

- Internet-facing ALB across two public subnets.
- ACM certificate validated through Whogohost DNS.
- HTTPS listener forwards to private ECS tasks on port 8000.
- HTTP listener redirects to HTTPS.
- ALB outbound traffic restricted to the ECS security group on port 8000.
- ECS inbound traffic allowed only from the ALB security group.
- Tasks have no public IPs.
- Target group checks /health and requires HTTP 200.
- Production configuration enables ALB deletion protection.

## Reported validation

- ACM certificate: ISSUED.
- ALB targets: healthy.
- HTTPS /health: HTTP 200 with the expected response.
- HTTPS /version: HTTP 200 with the deployed Git SHA.
- Certificate verification passed without curl -k.
- HTTP requests redirect to HTTPS.

Evidence is stored under docs/evidence/.
Production remains unapplied.

## DNS

Application: assessment.kunlekush.name.ng.
DNS remains at Whogohost.

Keep both the application CNAME pointing to the ALB and the ACM
validation CNAME. The validation record supports certificate renewal.

## Cost

The ALB adds ongoing runtime and usage charges.
