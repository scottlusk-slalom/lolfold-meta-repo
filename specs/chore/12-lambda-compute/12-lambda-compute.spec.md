---
type: chore
status: draft
priority: medium
created: 2026-03-23
updated: 2026-03-23
tags: ["infrastructure", "compute", "lambda", "simplification"]
related: ["01-infra-foundation", "02-api-foundation"]
---

# Swap ECS Fargate for Lambda

## Problem Statement

The API runs on ECS Fargate, which requires building Docker images, pushing to ECR, managing task definitions, and forcing redeployments on every code change. This is heavy operational overhead for a POC with low traffic and simple request/response patterns.

## Objectives

Replace ECS Fargate with Lambda + API Gateway (or Function URLs). Every merged PR should deploy in seconds, not minutes.

## Success Criteria

- [ ] API runs on Lambda behind API Gateway or CloudFront
- [ ] All existing endpoints work identically
- [ ] Deploy is a code push — no Docker builds, no ECR, no image management
- [ ] Cold start latency < 3 seconds
- [ ] Bedrock calls work correctly from Lambda execution environment

## Scope

### In Scope
- Wrap Express app in Lambda handler (e.g. `@vendia/serverless-express` or `aws-lambda-web-adapter`)
- Terraform: Add Lambda function, API Gateway, IAM roles
- Terraform: Remove ECS cluster, service, task definition, ALB, target groups, ECR
- Update CloudFront to point /api/* at API Gateway instead of ALB
- Database connectivity from Lambda (VPC config for RDS access)
- Prisma in Lambda (bundle considerations)

### Out of Scope
- API code changes beyond the Lambda wrapper
- Frontend changes
- Database schema changes
- Breaking apart into individual Lambda functions (keep monolith for now)

## Dependencies

- Spec 11 should be completed first (Bedrock model fix is code-level, not compute-level)
- RDS must remain accessible (Lambda needs VPC access to private subnets)

## Key Considerations

- **VPC Lambda:** Required for RDS access. Adds ~1-2s cold start. Mitigated with provisioned concurrency if needed.
- **Prisma on Lambda:** Works but needs `binaryTargets = ["native", "rhel-openssl-3.0.x"]` in schema.prisma. Bundle size matters.
- **Timeout:** Lambda max is 15 minutes. Bedrock calls take 2-5 seconds. Not an issue.
- **Migration on startup:** Current docker-entrypoint.sh runs Prisma migrate deploy on every container start. Lambda doesn't have an equivalent — run migrations separately (CI/CD step or one-off task).

## Infrastructure Changes

### Add
- Lambda function (Node.js 20 runtime)
- API Gateway HTTP API (or Lambda Function URL)
- Lambda execution role (Bedrock + RDS + Secrets Manager)
- Lambda VPC configuration (private subnets + security group)

### Remove
- ECS cluster, service, task definition
- ALB, target group, listener
- ECR repository, lifecycle policy
- ECS execution role, task role
- CloudWatch log group (replaced by Lambda's auto-created group)

### Modify
- CloudFront /api/* origin: ALB → API Gateway
- Security groups: Remove ECS SG, add Lambda SG with RDS access

## Repos
- **lolfold-infra**: Major terraform changes (add Lambda module, remove compute module)
- **lolfold-api**: Add Lambda handler wrapper, update prisma config, remove Dockerfile
