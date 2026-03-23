# Deployment Status

**Last Updated:** 2026-03-23
**Environment:** dev
**Region:** us-west-2

## Overview

All 9 specifications have been executed and deployed. The Lolfold POC is live and operational with the following infrastructure:

## Deployed Infrastructure

### Networking
- VPC: `vpc-0965c9c7793b6fd1d` (10.0.0.0/16)
- Public Subnets: 2 (us-west-2a, us-west-2b)
- Private Subnets: 2 (us-west-2a, us-west-2b)
- NAT Gateway: 1 (high availability not required for POC)
- Security Groups: ALB, ECS, RDS (with CloudFront prefix list access)

### Database
- RDS PostgreSQL 17.4
- Endpoint: `lolfold-dev-postgres.ceovobhauvyo.us-west-2.rds.amazonaws.com:5432`
- Database: `lolfold`
- Schema: Fully migrated (users, players, hands, sessions, hand_players, player_notes, hand_annotations)

### Compute
- ECS Fargate Cluster: `lolfold-dev`
- ECS Service: `lolfold-dev-api` (1 task running)
- ECR Repository: `446490546198.dkr.ecr.us-west-2.amazonaws.com/lolfold-dev-api`
- ALB: `lolfold-dev-api-578017548.us-west-2.elb.amazonaws.com`

### CDN & Storage
- S3 Bucket: `lolfold-dev-frontend`
- CloudFront Distribution: `E3M3A9WFU2SPSP`
- Domain: `d1uw756ov4qd1d.cloudfront.net`
- CloudFront Origins:
  - S3 (frontend static assets) via OAC
  - ALB (API proxy for /api/* paths)

### AI Services
- Bedrock Model: `us.anthropic.claude-sonnet-4-6` (inference profile)
- IAM Policy: Allows InvokeModel on foundation models and inference profiles

## Live URLs

- **Frontend:** https://d1uw756ov4qd1d.cloudfront.net
- **API:** https://d1uw756ov4qd1d.cloudfront.net/api/*
- **Health Check:** https://d1uw756ov4qd1d.cloudfront.net/api/health

## Completed Specifications

| Spec | Type | Status | PR(s) | Merged |
|------|------|--------|-------|--------|
| 01-infra-foundation | chore | ✅ completed | [infra#1](https://github.com/scottlusk-slalom/lolfold-infra/pull/1) | ✅ |
| 02-api-foundation | chore | ✅ completed | [api#1](https://github.com/scottlusk-slalom/lolfold-api/pull/1) | ✅ |
| 03-frontend-foundation | chore | ✅ completed | [frontend#1](https://github.com/scottlusk-slalom/lolfold-frontend/pull/1) | ✅ |
| 04-hand-input-parsing | feature | ✅ completed | [api#2](https://github.com/scottlusk-slalom/lolfold-api/pull/2), [frontend#2](https://github.com/scottlusk-slalom/lolfold-frontend/pull/2) | ✅ |
| 05-player-tracking | feature | ✅ completed | [api#3](https://github.com/scottlusk-slalom/lolfold-api/pull/3), [frontend#3](https://github.com/scottlusk-slalom/lolfold-frontend/pull/3) | ✅ |
| 06-search-filtering | feature | ✅ completed | [api#4](https://github.com/scottlusk-slalom/lolfold-api/pull/4), [frontend#4](https://github.com/scottlusk-slalom/lolfold-frontend/pull/4) | ✅ |
| 07-hand-replayer | feature | ✅ completed | [frontend#5](https://github.com/scottlusk-slalom/lolfold-frontend/pull/5) | ✅ |
| 08-session-tracking | feature | ✅ completed | [api#5](https://github.com/scottlusk-slalom/lolfold-api/pull/5), [frontend#6](https://github.com/scottlusk-slalom/lolfold-frontend/pull/6) | ✅ |
| 09-group-activity | feature | ✅ completed | [api#6](https://github.com/scottlusk-slalom/lolfold-api/pull/6), [frontend#7](https://github.com/scottlusk-slalom/lolfold-frontend/pull/7) | ✅ |

## Known Issues

### 1. Bedrock SDK Region Routing Issue (High Priority)

**Status:** Blocking AI features
**Impact:** Hand parsing, AI search, player summaries all fail with 403 AccessDenied

**Symptom:**
```
AccessDeniedException: User is not authorized to perform: bedrock:InvokeModel
on resource: arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-6
```

**Root Cause:**
The Bedrock SDK is routing inference profile requests to `us-east-1` instead of the configured `us-west-2` region. The IAM policy is correct (allows both foundation models and inference profiles), and the ECS environment variable `AWS_REGION=us-west-2` is set, but the SDK appears to be ignoring the region for inference profile ARNs.

**Next Steps:**
1. Debug BedrockRuntimeClient initialization in `src/services/bedrock.ts`
2. Test with direct foundation model ID instead of inference profile
3. Add explicit region override in Converse API calls
4. Or add us-east-1 to IAM policy as workaround

**Workaround Options:**
- Switch to direct foundation model: `anthropic.claude-3-5-sonnet-20240620-v1:0`
- Or add `arn:aws:bedrock:us-east-1::foundation-model/*` to IAM policy

## Deployment Notes

### Database Migrations
- Initial migration: `20260323000000_init` (creates all tables)
- Migrations run automatically on container startup via docker-entrypoint.sh
- Failed migrations from earlier deployments were cleared using `prisma migrate resolve`

### Container Image
- Built from `/tmp/lolfold-deploy/lolfold-api`
- Pushed to ECR with `:latest` tag
- Multi-stage build: Node 20 Alpine
- Includes Prisma client generation and migration tooling

### Security
- No authentication (per spec 10, deferred)
- Access restricted by:
  - ALB security group (VPC CIDR, operator IP, CloudFront prefix list)
  - RDS security group (ECS tasks only)
  - S3 bucket policy (CloudFront OAC only)

### Post-Deployment Fixes Applied
1. Added ECR repository for container images
2. Configured CloudFront /api/* origin to ALB (fixed mixed content HTTPS error)
3. Updated Bedrock IAM policy to include inference profiles
4. Resolved Prisma migration conflicts (cleared failed migration state)
5. Added database credentials to ECS task environment variables

## Rollback Procedure

If rollback is needed:

1. **Infrastructure:** `terraform apply` with previous commit
2. **API:** Redeploy previous ECS task definition revision
3. **Frontend:** Deploy previous S3 contents + invalidate CloudFront
4. **Database:** Prisma migration history can be resolved with `prisma migrate resolve`

## Monitoring

- ECS Task Health: Via ALB health checks (`/health`)
- Logs: CloudWatch Log Group `/ecs/lolfold-dev-api`
- Database: RDS Console metrics
- CloudFront: CloudFront metrics in us-east-1 (global service)

## Cost Optimization Notes

POC is not optimized for cost. Consider for production:
- Multi-AZ NAT Gateway (currently single AZ)
- RDS instance size (currently single instance)
- CloudFront cache TTLs (currently no cache on /api/*)
- ECR lifecycle policy (currently keeps last 10 images)
