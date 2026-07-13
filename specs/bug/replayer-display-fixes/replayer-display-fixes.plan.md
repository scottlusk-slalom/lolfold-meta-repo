# Cross-repo plan: replayer-display-fixes

**Type:** bug · **Quality gate:** standard · **Status:** awaiting plan approval

## Scope

Presentation-only fixes to the hand replayer poker table. Single repo, no
cross-repo dependencies. All changes in
`lolfold-frontend/src/components/replayer/PokerTable.tsx` (SVG felt), with
reference to `useReplayerState.ts` for the `step.players[]` shape.

## Repo sequence

1. **lolfold-frontend** (only repo) — `default_gate_level: standard`.

No `depends_on`; no ordering constraints. One sub-agent, one repo.

## Work summary (delegated to `/multi-repo-loop`)

The per-repo impl-plan, TDD execution, adversarial review, and PR are produced
inside `/multi-repo-loop <key> --repos lolfold-frontend --gates standard`. This
plan does not prescribe implementation. High-level intent, from the spec's four
bugs:

1. Every player seat persists for the whole hand (folded seats de-emphasized,
   never removed).
2. A player's cards are removed on fold (seat stays).
3. Dealer button always renders at the correct seat, robust to position-label
   variance (derive from hand data when label absent).
4. A player's two cards render adjacent (side by side), not flanking the seat.

## Acceptance / gates

- `npm run build`, `npm run test:run`, `npx tsc -b --noEmit` all pass.
- Tests added/adjusted for dealer-button placement (varied labels) and
  folded-player seat-retains-cards-removed.
- Desktop + mobile (mobile-first, Tailwind v4), dark mode correct.
- Replay logic/controls unchanged.

## Dispatch record

See `scratch/orchestrator.md`.
