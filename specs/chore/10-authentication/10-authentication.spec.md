---
type: chore
status: completed
priority: low
created: 2026-03-23
updated: 2026-03-23
tags: ["auth", "cognito", "google-oauth"]
related: ["01-infra-foundation", "02-api-foundation", "03-frontend-foundation"]
---

# Authentication Specification

## Problem Statement

The app currently has no authentication — access is restricted by IP at the security group level. Before opening this up to friends or any broader use, we need proper user authentication. Google sign-in via Cognito is the plan.

## Objectives

1. Add Cognito user pool with Google OAuth to the infrastructure
2. Add JWT validation middleware to the API
3. Add sign-in/sign-out flow to the frontend
4. Wire up the User model to authenticated identities

## Success Criteria

- [ ] Cognito user pool with Google OAuth provider provisioned via Terraform
- [ ] API validates Cognito JWTs on all protected routes (health check excluded)
- [ ] User identity extracted from token and available in request context
- [ ] Frontend redirects to Google sign-in when unauthenticated
- [ ] Frontend stores tokens and attaches them to API requests
- [ ] Sign-out works and clears session
- [ ] User record auto-created on first sign-in

## Scope

### In Scope
- Terraform: Cognito user pool, Google identity provider, app client
- API: JWT middleware using aws-jwt-verify, user upsert on first auth
- Frontend: OAuth redirect flow, auth context, protected routes
- Google Cloud Console: OAuth credentials setup (manual, documented)

### Out of Scope
- Email/password auth (Google only)
- Multi-factor authentication
- User roles or permissions (everyone is equal for now)

## Dependencies

- Specs 01-03 complete (infra, API, frontend all running without auth)
- Google Cloud project with OAuth consent screen configured

## References

- [Core PRD](../../../requirements/prd-core.md) — REQ-014
- [Org Standards](../../../org/standards.md)
