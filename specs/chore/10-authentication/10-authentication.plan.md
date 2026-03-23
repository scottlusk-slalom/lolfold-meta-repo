---
status: not_started
created: 2026-03-23
updated: 2026-03-23
---

# Authentication - Technical Implementation Plan

## Approach

Cross-cutting spec touching all three repos. Terraform adds Cognito with Google OAuth. API adds JWT validation middleware via `aws-jwt-verify`. Frontend adds the OAuth redirect flow and wires auth tokens into the API client.

## Key Decisions & Constraints

- Use Cognito hosted UI for the redirect flow — don't build a custom sign-in form
- `aws-jwt-verify` for API-side token validation (official AWS library, handles JWKS caching)
- On first authenticated request, upsert a User record from JWT claims (sub, email, name)
- Add cognito_sub column to User model (Prisma migration)
- Cognito callback URLs need both the CloudFront domain and localhost:5173 for local dev
- Google OAuth credentials must be created manually in Google Cloud Console — document the steps
- Frontend auth should be a context provider so any component can check auth state

## Milestones

- [ ] Cognito user pool + Google IdP provisioned via Terraform
- [ ] API JWT middleware protecting all routes except /health
- [ ] Frontend OAuth redirect flow working end-to-end
- [ ] User record auto-created on first sign-in
- [ ] API client attaching Bearer token to all requests

## Affected Systems

- **lolfold-infra** — New auth module (Cognito)
- **lolfold-api** — Auth middleware, User model migration
- **lolfold-frontend** — Auth flow, API client update

## Notes

- This produces one PR per repo (three PRs total).
- Google Cloud Console setup is manual — consider adding a doc with the steps to the infra repo README.
