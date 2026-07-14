---
status: approved
---

# Execution Plan — Hand replayer display fixes (v2)

Spec: `replayer-display-fixes-v2` (type: bug, quality_gate: standard)
Metarepo spec PR: #22

## Scope

Presentation-only fixes in `lolfold-frontend`, component
`src/components/replayer/PokerTable.tsx`. No change to replay logic, parsing,
or data. Four display bugs, all in the SVG poker felt.

## Repo sequence

Single repo — no cross-repo dependencies.

| # | Repo | depends_on | Gate | Notes |
|---|------|-----------|------|-------|
| 1 | lolfold-frontend | — | standard | All four fixes; presentation-only |

## Work (delegated to `/multi-repo-loop` in the sub-agent)

The sub-agent runs `/multi-repo-loop replayer-display-fixes-v2 --repos lolfold-frontend --gates standard` whole, which owns per-repo planning, TDD execution, adversarial review, and companion-PR submission. Summary of intended fixes:

1. **Whole table always visible** — every seat persists for the entire hand; a folded player's seat stays (may be de-emphasized), never removed.
2. **Cards removed on fold** — when a player folds, their cards (hero face-up and others' face-down) are removed at that replay step; seat remains.
3. **Dealer button always shown at correct seat** — make button placement robust to actual parser position labels (case-insensitive `btn`/`button`/`dealer`/`D`/`BU`, or derive the button seat from hand data when the label is absent). Never fall through to `-1`/no-render.
4. **Two cards adjacent** — a player's two cards render side by side on one side of the seat, not flanking it on opposite sides.

## Acceptance / quality gate (standard)

- `npm run build`, `npm run test:run`, `npx tsc -b --noEmit` all pass.
- Tests added/adjusted where practical (dealer-button placement for varied position labels; folded player retains seat but loses cards).
- Works desktop + mobile (mobile-first, Tailwind v4), dark mode correct.
- Replay logic/controls unchanged.

## Orchestration flow

1. (this gate) plan-review PAUSE — human approves the plan.
2. On approval: `/approve` → status `planned`; dispatch sub-agent for `lolfold-frontend`.
3. Sub-agent opens companion PR on `agent/bug/replayer-display-fixes-v2`, labels spec PR `sub-agent-complete`.
4. pr-review PAUSE — human reviews companion PR, decides merge.
5. On merge (last & only repo): `/update-gate executed` → `submitted`; spec-complete skipped (standard) → `/archive-spec`, push spec branch, merge PR #22 to `main` (= archived).
