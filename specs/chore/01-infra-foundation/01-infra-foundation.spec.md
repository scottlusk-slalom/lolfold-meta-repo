---
type: chore
status: completed
priority: high
created: 2026-03-22
updated: 2026-03-22
tags: ["infrastructure", "terraform", "aws"]
related: []
---

# Infrastructure Foundation Specification

## Problem Statement

We're building Lolfold from scratch and need the AWS infrastructure in place before any application code can run. This includes networking, database, and AI model access. Nothing else can move forward without this.

## Objectives

1. Stand up a VPC with proper networking and security groups that follow our org standards (no quad-zero ingress)
2. Provision a PostgreSQL database (RDS) for hand and player data
3. Enable Bedrock access for Claude model invocation
4. Set up hosting infrastructure for the frontend (S3 + CloudFront) and API (decide on ECS vs Lambda)
5. Establish the Terraform project structure with remote state

## Success Criteria

### Infrastructure
- [ ] VPC with public and private subnets in us-west-2
- [ ] Security groups allow only VPC CIDR + operator IP for inbound traffic
- [ ] RDS PostgreSQL instance running and accessible from private subnets
- [ ] Bedrock model access enabled for Claude (anthropic.claude-3-5-sonnet or similar)
- [ ] S3 bucket + CloudFront distribution for frontend hosting
- [ ] API compute (ECS Fargate or Lambda + API Gateway — pick whichever is simpler for a POC)

### Terraform
- [ ] Clean module structure, not one giant main.tf
- [ ] Remote state in S3 with DynamoDB lock table
- [ ] Outputs for everything downstream repos need (DB endpoint, API URL, CloudFront domain)
- [ ] tfvars or similar for environment-specific config

## Scope

### In Scope
- VPC, subnets, route tables, NAT gateway, internet gateway
- Security groups (API, DB, general)
- RDS PostgreSQL (single instance, not multi-AZ — it's a POC)
- Bedrock model access policy/role
- S3 + CloudFront for frontend
- API compute infrastructure
- Terraform remote state bootstrap
- IAM roles for API to access Bedrock and RDS

### Out of Scope
- **Authentication (Cognito, Google OAuth)** — deferred to a separate spec
- CI/CD pipelines
- Monitoring/alerting (CloudWatch basics are fine but no custom dashboards)
- Multi-environment setup (just one environment for now)
- Domain name / Route53 (CloudFront default domain is fine for POC)
- WAF, Shield, or any advanced security beyond security groups

## Dependencies

- AWS account with SSO access configured
- Terraform installed locally
- `gh` CLI authenticated for repo operations

## Assumptions

- Single-environment deployment (no dev/staging/prod split)
- No authentication for now — access is restricted by IP via security groups (org standard)
- RDS can use a small instance type (db.t3.micro or similar)
- We'll use the default VPC CIDR (10.0.0.0/16) unless there's a reason not to

## References

- [Product Brief](../../../project/product-brief.md)
- [Core PRD](../../../requirements/prd-core.md)
- [Org Standards](../../../org/standards.md)
- [Architecture](../../../architecture/00-lolfold.md)
