---
title: Execution plan — Hand replayer display fixes
spec: replayer-display-fixes
type: bug
quality_gate: standard
---

# Execution plan — replayer-display-fixes

Presentation-only bug fixes to the hand replayer poker table. Single repo,
no cross-repo dependencies. Detailed implementation planning (TDD steps,
file-level changes) happens inside `/multi-repo-loop` per repo.

## Repo scope & sequence

| # | Repo | Depends on | Rationale |
|---|------|-----------|-----------|
| 1 | `lolfold-frontend` | — | Only repo in spec scope. All four fixes live in `src/components/replayer/PokerTable.tsx`. |

No backend (`lolfold-api`) or infra (`lolfold-infra`) changes — this is
SVG/presentation only, no change to replay logic, parsing, or data.

## Work summary (delegated to /multi-repo-loop)

Four display bugs in `PokerTable.tsx`:
1. Seats persist for the whole hand — no player vanishes on fold/all-in.
2. Cards are removed on fold (seat remains); applies to hero + villains.
3. Dealer button always renders, at the correct seat, robust to position-label
   variants (or derived when the label is absent).
4. A player's two cards render adjacent (side by side), not flanking the seat.

## Gates (standard)

- spec-review: skipped
- plan-review: **PAUSE** (this gate)
- pr-review: PAUSE (per companion PR)
- spec-complete: skipped

Technical enforcement passed to loop: `--gates standard`.

## Acceptance (from spec)

Build, `npm run test:run`, and `npx tsc -b --noEmit` all pass; tests added/adjusted
for dealer-button placement across position labels and folded-player card removal;
desktop + mobile, dark mode correct; replay logic/controls unchanged.
