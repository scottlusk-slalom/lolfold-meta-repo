---
title: Execution plan — Hand replayer display fixes
spec: replayer-display-fixes
type: bug
status: approved
quality_gate: standard
repos:
  - lolfold-frontend
---

# Execution Plan — replayer-display-fixes

Cross-repo sequencing plan for the orchestrator. Per-repo implementation
planning, TDD, adversarial review, and PR submission are owned by
`/multi-repo-loop` and are NOT expanded here.

## Scope

Single repo, presentation-only. Four display bugs in the hand replayer's SVG
poker table, all localized to `lolfold-frontend`
(`src/components/replayer/PokerTable.tsx`). No change to replay logic, parsing,
or data.

## Repo sequence

1. **lolfold-frontend** — only repo. No `depends_on`; no cross-repo contract.

Serialized dispatch (one sub-agent, one repo). Since there is exactly one repo,
a single dispatch → single `pr-review` gate → merge → archive.

## Per-repo dispatch

Each repo is dispatched to a cloud sub-agent that runs, whole:

```
/multi-repo-loop replayer-display-fixes --repos lolfold-frontend --gates standard
```

The loop owns: impl-plan, TDD execution, adversarial review, companion PR on
branch `agent/bug/replayer-display-fixes`.

## Quality gate: standard

- spec-review: skip
- plan-review: PAUSE (this gate)
- pr-review: PAUSE (after the frontend companion PR opens)
- spec-complete: skip
- technical enforcement passed to loop: `--gates standard`

## Acceptance (from spec)

- All seats persist for the whole hand; folded players keep their seat, lose
  their cards.
- Dealer button renders on every hand at the correct seat, robust to position
  label variance.
- Each player's two cards render adjacent (side by side).
- `npm run build`, `npm run test:run`, `npx tsc -b --noEmit` all pass.
- Tests added/adjusted where practical.

## Risks / notes

- Presentation-only; low blast radius. Main risk is button-seat derivation when
  the position label is absent/non-standard — the loop must add coverage for
  varied position labels.
- Verify against real hands (a fold case + a non-standard button label).
