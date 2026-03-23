# Execution Plan: Swap ECS for Lambda

## Approach

Replace ECS with a single Lambda function running the existing Express app via `@vendia/serverless-express`. Keep the API as a monolith — don't break into individual functions. Use API Gateway HTTP API as the trigger, and update CloudFront to route /api/* there.

## Key Decisions & Constraints

- **Monolith Lambda:** One function, full Express app. Simplest migration path.
- **VPC Lambda:** Required for RDS access. Accept cold start tradeoff (~2s).
- **API Gateway HTTP API:** Cheaper and faster than REST API. Supports all HTTP methods.
- **Migrations:** Run as a separate step (CI script or manual), not on Lambda cold start.
- **Prisma:** Add `rhel-openssl-3.0.x` binary target. Consider `@prisma/client` bundle size.

## Milestones

### 1. Add Lambda Handler to API
- Install `@vendia/serverless-express`
- Create `src/lambda.ts` that wraps the Express app
- Update `prisma/schema.prisma` with Lambda binary target
- Test locally with `sam local invoke` or similar

### 2. Terraform: Add Lambda Infrastructure
- New `modules/lambda/` module: function, API Gateway HTTP API, IAM role, VPC config
- Lambda security group with RDS access
- API Gateway with `$default` route proxying to Lambda
- CloudWatch log group

### 3. Terraform: Update CloudFront
- Change /api/* origin from ALB to API Gateway endpoint

### 4. Terraform: Remove ECS Infrastructure
- Remove `modules/compute/` (cluster, service, task def, ALB, ECR, roles)
- Remove ALB security group from networking module
- Clean up root module references and outputs

### 5. Deploy and Validate
- Apply terraform
- Run Prisma migrations manually against RDS
- Test all API endpoints through CloudFront
- Verify Bedrock calls work from Lambda

## Affected Systems
- lolfold-api (add Lambda handler, update Prisma config, remove Dockerfile)
- lolfold-infra (new Lambda module, remove compute module, update CDN)

## Risks
- **Prisma bundle size:** May need to optimize with `prisma generate --no-engine` or esbuild
- **Cold starts:** VPC Lambda cold starts ~2-3s. Acceptable for POC.
- **Connection pooling:** Lambda can exhaust RDS connections under load. Mitigate with RDS Proxy if needed (not needed for POC).
