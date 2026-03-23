---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# API Foundation - Technical Implementation Plan

## Approach

Standard Express + TypeScript project. Prisma for ORM and migrations — gives type-safe DB access and schema-first design. Layered structure: routes, controllers, services, middleware.

No authentication. Access restricted by infrastructure (security groups). The User model exists in the schema for when auth is added later, but there's no middleware enforcing it.

Bedrock client is a thin wrapper around `@aws-sdk/client-bedrock-runtime` — invoke Claude with a prompt, get structured output back. Feature specs will use this without caring about the AWS plumbing.

## Key Decisions & Constraints

- Prisma as ORM (not Knex, not raw SQL). Schema-first, good TS integration.
- No auth middleware. No JWT validation. No Cognito dependencies.
- User model still exists (email, display_name) — auth spec will add cognito_sub later
- The schema needs: User, Player (with aliases array), Session, Hand (with raw_input + parsed_data JSONB + denormalized filter fields), HandPlayer (join), PlayerNote, HandAnnotation
- Hand.parsed_data is intentionally JSONB — the structure will be defined in spec 04
- Denormalized fields on Hand (hero_position, pot_type, street_reached, num_players) exist for efficient filtering
- CORS must allow the CloudFront frontend domain
- Dockerfile should be multi-stage (build TS, then run with node)

## Milestones

- [ ] Express + TS project scaffolded, builds and runs locally
- [ ] Prisma schema covers all core entities, migrations generated
- [ ] Bedrock client wrapper working (test endpoint that invokes Claude)
- [ ] Health check at GET /health
- [ ] Dockerfile builds and runs locally

## Affected Systems

- **lolfold-api** — All application code
- **lolfold-infra** — May need ECR repo if not created in spec 01

## Risks

| Risk | Mitigation |
|------|------------|
| Bedrock model access might not be enabled in the account | Check console / request access before starting |
| Prisma migrations need DB connectivity | For the PR, just generate migrations locally. Apply happens at deploy time. |

## Notes

- The parsed_data JSONB structure is intentionally undefined here. Spec 04 (hand parsing) will define it. Just make sure the column exists.
- Don't forget .env.example with all required env vars documented.
