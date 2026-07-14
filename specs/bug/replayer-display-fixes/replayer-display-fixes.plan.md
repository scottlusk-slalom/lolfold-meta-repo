# Execution Plan — replayer-display-fixes

**Spec:** `specs/bug/replayer-display-fixes/replayer-display-fixes.spec.md`
**Type:** bug · **Quality gate:** standard

## Scope

Presentation-only fixes to the hand replayer poker table. Single repo, no
cross-repo contracts, no data/logic changes.

| Repo | Change | Gate |
|---|---|---|
| lolfold-frontend | Fix 4 display bugs in `src/components/replayer/PokerTable.tsx` | standard |

## Repo sequence

Single repo → single sub-agent. No `depends_on` ordering.

1. **lolfold-frontend** — dispatch `/multi-repo-loop replayer-display-fixes --repos lolfold-frontend --gates standard`

## Work summary (all in `PokerTable.tsx`)

1. Keep every player seat visible for the whole hand (folded seats persist,
   may be de-emphasized).
2. Remove only the CARDS when a player folds (hero face-up + others face-down).
3. Always render the dealer button at the correct seat; make button placement
   robust to varied/absent `position` labels.
4. Draw each player's two cards adjacent (side by side), not flanking the seat.

## Verification

- `npm run build`, `npm run test:run`, `npx tsc -b --noEmit` all pass.
- Add/adjust tests: dealer-button placement across position labels; folded
  player retains seat but loses cards.
- Manual verify against real hands (a fold, a non-standard button label);
  desktop + mobile, dark mode.

## Gates

- `plan-review` (this gate) — human approves plan → `/approve` → `planned`.
- `pr-review` — after companion PR opens, human decides merge/hold/rollback.
