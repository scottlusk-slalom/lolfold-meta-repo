---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Infrastructure Foundation - Technical Implementation Plan

## Approach

Terraform with a modular structure — one module per concern (networking, database, compute, cdn, ai). Remote state in S3 with DynamoDB lock table, bootstrapped separately.

ECS Fargate for the API compute. Lambda + API Gateway is an option but ECS is more natural for a persistent Express app that holds connections to RDS. Fargate avoids EC2 management.

Single-AZ RDS PostgreSQL. No replicas, no multi-AZ — it's a POC for <10 users.

No authentication module. Access restricted by security groups per org standards.

## Key Decisions & Constraints

- Modules: networking, database, compute, cdn, ai — no auth module in this spec
- Security groups: ALB allows VPC CIDR + operator IP only. ECS from ALB only. RDS from ECS only. No quad-zero. Ever.
- ECS task definition uses a placeholder image — spec 02 replaces it with the real API
- All downstream config (DB endpoint, ALB DNS, CloudFront domain) must be exposed as Terraform outputs
- Use tfvars.example with placeholder values so the repo is self-documenting
- RDS credentials go in Secrets Manager, not tfvars

## Milestones

- [ ] Remote state backend bootstrapped (S3 + DynamoDB)
- [ ] Terraform project structure with all modules wired up from root
- [ ] VPC, subnets, and security groups provisioned
- [ ] RDS PostgreSQL in private subnets
- [ ] ECS Fargate cluster + ALB with placeholder task
- [ ] S3 + CloudFront for frontend hosting
- [ ] Bedrock IAM policy attached to ECS task role
- [ ] `terraform validate` and `terraform plan` pass clean

## Affected Systems

- **lolfold-infra** — All Terraform code

## Risks

| Risk | Mitigation |
|------|------------|
| NAT gateway cost (~$30/mo) for a POC | Accept for now, revisit if cost matters |
| ECS task has no real image yet | Placeholder image is fine, spec 02 handles it |

## Notes

- Outputs are critical — specs 02 and 03 depend on them. Document what each output is for.
- ALB listener is HTTP for now. HTTPS needs a cert/domain, which is out of scope.
