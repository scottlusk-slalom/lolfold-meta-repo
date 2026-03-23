---
type: chore
status: completed
priority: high
created: 2026-03-22
updated: 2026-03-22
tags: ["api", "backend", "typescript", "express"]
related: ["01-infra-foundation"]
---

# API Foundation Specification

## Problem Statement

With infrastructure in place from spec 01, we need the backend API service scaffolded and deployed. This is the foundation that every feature will build on — the Express app, the database schema, authentication middleware, and the Bedrock client for AI calls. Nothing user-facing works without this.

## Objectives

1. Scaffold a Node.js/Express/TypeScript API project with a clean, conventional structure
2. Define and apply the initial PostgreSQL database schema for hands, players, notes, and sessions
3. Set up a Bedrock client wrapper for Claude model invocation
4. Deploy the API to ECS Fargate (updating the placeholder from spec 01)
5. Expose a health check and at minimum one working endpoint to prove the full stack works end-to-end

## Success Criteria

### API Project
- [ ] Express + TypeScript project builds and runs locally
- [ ] Linting and formatting configured (ESLint + Prettier or similar)
- [ ] Clean folder structure: routes, controllers, services, models, middleware
- [ ] Environment config via env vars (DB connection, Cognito settings, Bedrock config)

### Database
- [ ] Schema migrations set up (Knex, Prisma, or similar)
- [ ] Initial schema covers: users, players, hands (with raw_input field), hand_actions, player_notes, sessions
- [ ] Migrations run against the RDS instance successfully

### AI Integration
- [ ] Bedrock client wrapper that can invoke Claude
- [ ] A simple test endpoint or script that confirms Bedrock connectivity

### Deployment
- [ ] Docker image builds and runs
- [ ] Pushed to ECR, ECS task definition updated
- [ ] Health check endpoint returns 200 through the ALB

## Scope

### In Scope
- Project scaffolding and tooling
- Database schema design and migration setup
- Cognito auth middleware
- Bedrock client wrapper
- Docker + ECR + ECS deployment
- Health check endpoint
- Basic error handling and logging

### Out of Scope
- Feature endpoints (hand submission, player CRUD, search — those come in later specs)
- API documentation (Swagger/OpenAPI — nice to have later)
- Rate limiting, caching, or performance optimization
- Automated tests beyond basic smoke tests

## Dependencies

- Spec 01 complete: VPC, RDS, ECS cluster, ALB all provisioned
- Terraform outputs from spec 01: DB endpoint, ECR repo URI, ALB DNS
- AWS CLI authenticated via SSO

## Assumptions

- We'll use Prisma for the ORM/migrations — it has good TypeScript support and schema-first design
- The API runs as a single Express process in a Fargate container (no worker processes yet)
- No authentication for now — access restricted by IP at the infrastructure level (security groups). Auth will be added in a later spec.
- CORS configured to allow requests from the CloudFront frontend domain

## References

- [Product Brief](../../../project/product-brief.md)
- [Core PRD](../../../requirements/prd-core.md)
- [Architecture](../../../architecture/00-lolfold.md)
- [Infra Spec](../01-infra-foundation/01-infra-foundation.spec.md)
