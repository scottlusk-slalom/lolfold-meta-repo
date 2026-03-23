---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Session Tracking - Technical Implementation Plan

## Approach

Straightforward CRUD. The Session model already exists from spec 02. The main new concept is "active session" — a flag that auto-associates new hands with the current session. Only one active session per user at a time.

## Key Decisions & Constraints

- Active session is a user-level state (flag on session record or separate user preference)
- When creating a hand with no explicit session_id and user has an active session, auto-associate
- Session create form should default date to today and remember recent locations

## Milestones

- [ ] Session CRUD endpoints (create, list, detail, update)
- [ ] Active session: activate, deactivate, auto-associate hands
- [ ] Session list and detail pages in the frontend
- [ ] Active session indicator in the app shell
- [ ] Create session flow with activate option

## Affected Systems

- **lolfold-api** — Session endpoints, hand creation auto-association
- **lolfold-frontend** — Sessions tab, session detail, active session indicator, create flow

## Notes

- The active session indicator should be subtle but persistent — maybe a small banner or badge. You're at a table, you don't want it in the way, but you want to know it's tracking.
