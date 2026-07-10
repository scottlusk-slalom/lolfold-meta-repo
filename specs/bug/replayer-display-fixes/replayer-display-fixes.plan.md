---
key: replayer-display-fixes
type: bug
quality_gate: standard
repos:
  - lolfold-frontend
---

# Cross-repo execution plan — replayer-display-fixes

## Scope
Single repo: **lolfold-frontend**. Presentation-only fixes in the SVG poker
table (`src/components/replayer/PokerTable.tsx`), rendered via
`HandDetailPage.tsx → HandReplayer.tsx`. No API, no infra, no replay-logic
changes.

## Repo sequence
1. `lolfold-frontend` — the only repo. No `depends_on`; no cross-repo ordering.

## What the sub-agent runs
`/multi-repo-loop replayer-display-fixes --repos lolfold-frontend --gates standard`
whole, on branch `agent/bug/replayer-display-fixes`. It owns planning, TDD
execution, adversarial review, and PR submission for the four fixes:

1. Seats persist for the whole hand (no player vanishes on fold/all-in).
2. Cards removed on fold (seat stays) — hero face-up and others' face-down.
3. Dealer button always rendered at the correct seat, robust to position-label
   variants (lower/upper case, btn/button/dealer/D/BU, or derived from hand data).
4. A player's two cards drawn adjacent (side by side), not flanking the seat.

## Quality gate
`standard` — passed to the loop as `--gates standard`. Technical enforcement:
`npm run build`, `npm run test:run`, `npx tsc -b --noEmit` must pass; add/adjust
tests for dealer-button placement and folded-player-retains-seat.

## Human gates (standard)
- spec-review: skip
- plan-review: PAUSE (this gate)
- pr-review: PAUSE (per repo)
- spec-complete: skip

## Notes
Old-protocol artifacts on `main` (stale `spec.yaml`, closed status issue #11)
are irrelevant; this branch's `replayer-display-fixes.spec.md` is authoritative.
