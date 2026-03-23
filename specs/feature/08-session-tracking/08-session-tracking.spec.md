---
type: feature
status: completed
priority: medium
created: 2026-03-22
updated: 2026-03-22
tags: ["sessions", "organization"]
related: ["04-hand-input-parsing"]
---

# Session Tracking Specification

## Problem Statement

Hands need to be organized by poker session — "Tuesday night at the Bellagio, $2/$5, 6 hours." Sessions give hands temporal and contextual grouping. Users want to browse "what happened last session" or look at hands from a specific game.

## Objectives

1. Create and manage poker sessions (date, location, stakes, game type)
2. Associate hands with sessions
3. Session list view for browsing
4. Active session concept — when you're at the table, your current session is active and new hands auto-associate with it

## Success Criteria

- [ ] User can create a session with: date, location, stakes, game type, optional notes
- [ ] User can set a session as "active" — new hands auto-associate with it
- [ ] Session list page shows sessions chronologically with hand counts
- [ ] Session detail page shows all hands from that session
- [ ] User can manually associate or disassociate hands with sessions
- [ ] Only one active session at a time

## Scope

### In Scope
- Session CRUD (create, read, update)
- Active session state
- Session list and detail pages
- Hand-session association
- Game variant info on sessions (straddles, bounty games, etc.)

### Out of Scope
- Session P&L tracking (buy-in, cash-out) — could-have, not now
- Session sharing or social features
- Multi-session comparison

## Dependencies

- Spec 04 complete (hands exist)
- Spec 03 complete (app shell with Sessions tab)

## References

- [Core PRD](../../../requirements/prd-core.md) — REQ-017, REQ-018
