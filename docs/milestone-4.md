# Milestone 4 — AWS networking

## Design

One shared networking module serves dev and prod.

Each environment defines:
- VPC: 10.0.0.0/16.
- Two public and two private /24 subnets across eu-west-2a and eu-west-2b.
- Internet Gateway and a shared public route table.
- One private route table per AZ.
- Automatic subnet public IP assignment disabled.

Public default routes point to the Internet Gateway.
Private default routes point to NAT Gateways.

Dev uses one NAT Gateway in AZ-a. Both private subnets depend on it
for outbound access. This reduces gateway costs but introduces an
AZ-a dependency and possible cross-AZ traffic charges.

Prod defines one NAT Gateway per AZ for resilient outbound access.

## Deployment and validation

Dev was applied and its subnet, route and NAT checks were reported
complete. The post-apply plan was reported unchanged.
Command evidence is stored under docs/evidence/.

Prod remains configured but unapplied.

Application connectivity is not yet verified; ECS deployment will
provide that acceptance test.

## Security and cost

Private subnets have no direct Internet Gateway default route.
NAT supports outbound connections without unsolicited inbound access.
Application security groups will be configured with the ECS/ALB work.

NAT Gateway runtime, data processing and public IPv4 addresses incur
charges while provisioned. No application compute exists yet.
