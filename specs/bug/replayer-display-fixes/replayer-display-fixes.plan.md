# Cross-repo execution plan — replayer-display-fixes

Spec: `specs/bug/replayer-display-fixes/replayer-display-fixes.spec.md`
Type: bug · Quality gate: `standard`

## Scope

Presentation-only fixes to the hand replayer poker table. Single repo.

| # | Repo | depends_on | Gate | Sub-agent |
|---|------|-----------|------|-----------|
| 1 | lolfold-frontend | — | standard | `/multi-repo-loop replayer-display-fixes --repos lolfold-frontend --gates standard` |

No cross-repo dependencies. One repo → one sub-agent → one companion PR on
`agent/bug/replayer-display-fixes`.

## Work (all in `src/components/replayer/PokerTable.tsx`)

1. Every player seat stays visible for the whole hand (no seat vanishes).
2. Cards are removed when a player folds; the seat persists.
3. Dealer button always renders at the correct seat, robust to position-label
   variants (or derived from hand data when the label is absent).
4. A player's two cards render adjacent (side by side), not flanking the seat.

Per-repo TDD implementation detail, adversarial review, and test additions are
produced inside `/multi-repo-loop` (not planned here).

## Verification (owned by the loop)

`npm run build`, `npm run test:run`, `npx tsc -b --noEmit` all pass. Desktop +
mobile, dark mode correct. Replay logic/controls unchanged.

## Orchestration sequence

1. plan-review gate (this PAUSE) → human `Decision: approved` → `/approve`.
2. Dispatch lolfold-frontend sub-agent (serialized; only repo).
3. Sub-agent opens companion PR, labels spec PR `sub-agent-complete`.
4. pr-review gate (PAUSE) → human `Decision: merge` → merge companion PR.
5. All repos merged → `executed` → `submitted` → archive (merge spec PR to main).
