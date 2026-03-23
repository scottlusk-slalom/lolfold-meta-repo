---
type: feature
status: completed
priority: medium
created: 2026-03-22
updated: 2026-03-22
tags: ["replayer", "visualization", "frontend"]
related: ["04-hand-input-parsing", "06-search-filtering"]
---

# Hand Replayer Specification

## Problem Statement

Reading a structured hand as text is functional but not intuitive. A visual replayer that shows a poker table with players in their seats, chips in the middle, and cards on the board makes reviewing hands much more engaging and easier to follow. You should be able to click through a hand action by action, watching the pot grow and stacks shrink, like watching a hand on TV.

## Objectives

1. Visual top-down poker table rendering with player seats
2. Show player names, positions, and stack sizes at each seat
3. Click-through action replay: step forward/backward through the hand action by action
4. Only Hero's hole cards shown face-up; villains are face-down unless showdown occurred
5. Board cards appear street by street
6. Pot and stack sizes update in real time as you step through

## Success Criteria

- [ ] Table renders with correct number of players in proper positions
- [ ] Stack sizes shown next to each player, updating as bets go in
- [ ] Pot displayed in center, updating with each action
- [ ] Board cards appear on flop (3), turn (1), river (1)
- [ ] Hero's cards always shown; villain cards hidden (face-down placeholder)
- [ ] If showdown data exists, villain cards revealed at showdown step
- [ ] Forward/back buttons to step through actions
- [ ] Current action highlighted (who did what)
- [ ] Street labels visible (Preflop, Flop, Turn, River)
- [ ] Works well on mobile (the primary device)

## Scope

### In Scope
- Table rendering component (SVG or Canvas)
- Action step-through controls
- Card rendering (simple card graphics, doesn't need to be fancy)
- Pot and stack tracking
- Mobile-optimized layout
- Embedding in the hand detail page

### Out of Scope
- Animated card dealing / chip movement (nice to have later, not needed)
- Sound effects
- Sharing replayer as a standalone link
- Equity calculations or range displays
- Multi-table view

## Dependencies

- Spec 04 complete (structured hand data in parsed_data JSON)
- Spec 06 complete (hand detail page exists to embed the replayer in)

## Assumptions

- The parsed_data JSON structure has all the info needed: players, positions, stacks, actions per street, board cards, hero cards
- Simple card graphics are fine — text on colored rectangles, or a basic SVG card set. This is a POC, not a casino app.
- Table positions are relative to Hero (Hero always at bottom center)

## References

- [Core PRD](../../../requirements/prd-core.md) — REQ-011, REQ-012, REQ-013
