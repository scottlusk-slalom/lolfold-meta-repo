---
type: chore
status: completed
priority: high
created: 2026-03-22
updated: 2026-03-22
tags: ["frontend", "react", "typescript"]
related: ["01-infra-foundation", "02-api-foundation"]
---

# Frontend Foundation Specification

## Problem Statement

With infra and API in place, we need the React frontend scaffolded: authentication flow working with Cognito/Google, a basic app shell with routing, dark mode, and the mobile-first layout. This is the container that every feature UI will live in.

## Objectives

1. Scaffold a Vite + React + TypeScript project
2. Build an app shell with navigation, routing, and dark mode
3. Set up the API client layer so feature specs can easily call backend endpoints
4. Deploy to S3 + CloudFront
5. Confirm the full end-to-end loop: frontend loads, calls API, gets a response

## Success Criteria

### App Shell
- [ ] Mobile-first responsive layout
- [ ] Dark mode by default
- [ ] Bottom navigation bar (mobile) with tabs for: Hands, Players, Sessions, Profile
- [ ] Basic routing for each tab (placeholder pages are fine)
- [ ] "New Hand" button is always 1 tap away from any screen

### API Integration
- [ ] Typed API client that handles base URL and error responses
- [ ] Health check call on app load confirms backend connectivity
- [ ] Loading and error states handled generically

### Deployment
- [ ] Production build outputs to S3
- [ ] CloudFront serves the app

## Scope

### In Scope
- Vite + React + TS project setup
- App shell: layout, nav, routing
- Dark mode (CSS variables or Tailwind dark mode)
- API client wrapper
- S3 + CloudFront deployment
- Placeholder pages for each main section

### Out of Scope
- **Authentication** — deferred to a later spec
- Any feature UI (hand input form, player profiles, replayer — those come in later specs)
- PWA/service worker (not needed for POC)
- Unit tests beyond basic smoke tests
- State management library (start with React context, add zustand/redux if needed later)

## Dependencies

- Spec 01 complete: CloudFront distribution, ALB
- Spec 02 complete: API running behind ALB with /health endpoint

## Assumptions

- Tailwind CSS for styling — fast to work with, good dark mode support, mobile-first by default
- React Router for routing
- No authentication for now — access restricted by IP at the infrastructure level. Auth will be added in a later spec.
- The API client will use fetch or axios — no GraphQL, just REST

## References

- [Product Brief](../../../project/product-brief.md)
- [Core PRD](../../../requirements/prd-core.md) — see UI/UX Considerations section
- [Architecture](../../../architecture/00-lolfold.md)
- [Infra Spec](../01-infra-foundation/01-infra-foundation.spec.md)
- [API Spec](../02-api-foundation/02-api-foundation.spec.md)
