---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Group Activity Feed - Technical Implementation Plan

## Approach

Simple aggregation query across hands and player notes from all users, sorted by date. No separate activity table — just query existing tables and present as a feed. If we need more activity types later (quiz results, reactions), we'd add a dedicated activity table then.

V1 = all users share one group. No group management.

## Key Decisions & Constraints

- Feed items are either "hand recorded" or "note added" — two types for now
- Player names in feed items should be tappable links to player profiles
- The activity item component should be extensible for future types (decision point quiz in v1.01)
- Don't add a 5th tab — integrate the feed into the existing nav (top of Hands tab, or a section)

## Milestones

- [ ] API endpoint: GET /api/activity returning merged hand + note activity, paginated
- [ ] Activity feed UI with hand and note items
- [ ] Player name and hand linking from feed items
- [ ] User's own activity visually distinguished from others'

## Affected Systems

- **lolfold-api** — Activity feed endpoint
- **lolfold-frontend** — Activity feed UI

## Notes

- This is a lightweight feature. Don't over-build. A reverse-chronological list is all it needs.
- No real-time push — polling on page load is fine for a POC with <10 users.
