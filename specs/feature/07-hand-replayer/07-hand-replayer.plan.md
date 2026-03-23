---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Hand Replayer - Technical Implementation Plan

## Approach

Pure frontend component — no new API endpoints. Reads parsed_data JSON from the hand record and renders it visually.

SVG-based table rendering. SVG scales well across devices and is easy to position precisely. Players sit around an oval table with Hero always at bottom center. A step index state controls what's visible: which actions have played, current pot, current stacks, board cards revealed.

Controls: forward, back, and street-jump buttons (preflop/flop/turn/river). Keep it simple.

## Key Decisions & Constraints

- Hero always at bottom center of the table. Other players positioned clockwise relative to Hero.
- Support 2-10 player positions
- Cards are simple: text rank + suit on a rectangle. Not fancy. Functional and clear.
- Hero's cards always face-up. Villains face-down unless showdown data exists.
- The replayer is a self-contained component — keep it portable enough that the decision point quiz (v1.01) can reuse it with a "stop at step X" prop.
- Mobile is the primary viewport. Table must be readable on 375px width.

## Milestones

- [ ] Replayer state machine: given parsed hand, compute full step sequence with pot/stack state at each step
- [ ] SVG table rendering with player seats, cards, pot, and board
- [ ] Step-through controls (forward, back, street jump)
- [ ] Embedded in hand detail page
- [ ] Works on mobile and desktop

## Affected Systems

- **lolfold-frontend** — Replayer component, hand detail page integration

## Risks

| Risk | Mitigation |
|------|------------|
| SVG positioning is fiddly with varying player counts | Start with 6-seat layout, then generalize |
| Table might be cramped on small screens | Prioritize table size, minimal controls bar. Allow pinch-zoom if needed. |

## Notes

- Functional and clear beats pretty. A clean SVG with text labels is fine for the POC.
- No animations needed — just update numbers and positions on each step.
