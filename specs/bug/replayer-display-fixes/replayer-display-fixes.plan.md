---
title: Plan — Hand replayer display fixes
type: bug
key: replayer-display-fixes
quality_gate: standard
repos:
  - lolfold-frontend
---

# Cross-repo plan — replayer-display-fixes

Presentation-only bug fix, single repo. No cross-repo contracts, no API/infra
changes. All four fixes land in `lolfold-frontend`, primarily
`src/components/replayer/PokerTable.tsx`.

## Repo scope & order

| # | Repo | Depends on | Notes |
|---|------|-----------|-------|
| 1 | lolfold-frontend | — | Only repo in scope. |

No `depends_on` relationships; single-repo dispatch.

## Work summary (delegated to /multi-repo-loop)

The per-repo loop owns detailed impl-planning, TDD, review, and PR. Scope:

1. **Seats always visible** — every player seat persists the whole hand; folded
   seats may de-emphasize but never disappear.
2. **Cards removed on fold** — remove a player's cards (hero face-up + others
   face-down) at the fold step; seat stays.
3. **Dealer button always shown, correct seat** — make button-seat detection
   robust to actual position labels (case-insensitive btn/button/dealer/D/BU)
   or derive from hand data; button renders on every hand.
4. **Two cards adjacent** — draw a player's two cards side-by-side on one side
   of the seat, not flanking it.

## Acceptance (from spec)

- All four behaviors correct; desktop + mobile; dark mode.
- Replay logic/controls unchanged.
- `npm run build`, `npm run test:run`, `npx tsc -b --noEmit` pass.
- Tests added/adjusted where practical (dealer-button placement for varied
  labels; folded player retains seat, loses cards).

## Gating

- quality_gate: standard → plan-review PAUSE (this gate), pr-review PAUSE.
- Loop dispatched with `--gates standard`.
