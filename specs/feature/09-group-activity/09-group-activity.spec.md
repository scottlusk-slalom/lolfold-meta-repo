---
type: feature
status: completed
priority: medium
created: 2026-03-22
updated: 2026-03-22
tags: ["social", "group", "activity-feed"]
related: ["04-hand-input-parsing", "05-player-tracking"]
---

# Group Activity Feed Specification

## Problem Statement

When you and your friends are all tracking hands, you want to know when someone records a hand against a player you both know. "Jake played 3 hands against Pete last night" is useful intel before your next session. The group needs a shared awareness of what's being recorded.

## Objectives

1. Activity feed showing recent hand submissions from all group members
2. Player names highlighted — tap to go to their profile
3. Enough context to be useful at a glance without cluttering the feed

## Success Criteria

- [ ] Activity feed page/tab shows recent activity from all users in the group
- [ ] Each activity item shows: who recorded it, when, brief hand summary (villain names, pot type, street reached)
- [ ] Player names in the feed are tappable links to player profiles
- [ ] Feed updates when new hands are added (polling or on page load is fine, no need for real-time push)
- [ ] User can distinguish their own activity from others'

## Scope

### In Scope
- Activity feed showing hand submissions from the shared group
- Basic activity item component
- Player name linking
- Note submissions in the feed (when someone adds a note about a player)

### Out of Scope
- Real-time push notifications (polling on page load is fine for POC)
- Comments or reactions on activity items
- Decision point quiz (v1.01 stretch goal — will build on top of this feed)
- Group management (v1 = everyone in one group)

## Dependencies

- Specs 04 and 05 complete (hands and players exist)
- Spec 03 complete (app shell for the feed to live in)

## Assumptions

- V1 = all users share one group. No group management needed yet.
- The feed is a simple reverse-chronological list of hand submissions and note additions.
- This is low-effort since the data already exists — we just need a view that aggregates it across users.

## References

- [Core PRD](../../../requirements/prd-core.md) — REQ-028
