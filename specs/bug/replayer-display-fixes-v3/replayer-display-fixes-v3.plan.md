# Execution Plan — replayer-display-fixes-v3

Cross-repo sequencing plan for the orchestrator. Per-repo implementation
planning (TDD, adversarial review) happens inside `/multi-repo-loop`.

## Scope

- **Type:** bug (presentation-only)
- **Quality gate:** standard
- **Repos:** `lolfold-frontend` (single repo — no `depends_on`, no cross-repo ordering)

## Repo sequence

1. `lolfold-frontend` — the only repo. All four display fixes live in
   `src/components/replayer/PokerTable.tsx`.

Single repo ⇒ one sub-agent, one companion PR, one `pr-review` gate.

## Work summary (delegated to `/multi-repo-loop`)

Four display bugs in the hand replayer poker table (`PokerTable.tsx`):

1. Every player seat stays visible for the whole hand (no seat vanishes on fold/all-in).
2. A player's cards are removed on fold (seat persists, cards go — hero & non-hero).
3. Dealer button always renders at the correct seat, robust to position-label variance.
4. Each player's two cards render adjacent (side by side), not flanking the seat.

Presentation-only: no change to replay logic, parsing, or data.

## Gate flow (standard)

- spec-review: skip
- plan-review: **PAUSE** (this gate)
- pr-review: **PAUSE** (after companion PR opens)
- spec-complete: skip → archive on merge

## Verification (enforced by the loop, `--gates standard`)

- `npm run build`, `npm run test:run`, `npx tsc -b --noEmit` all pass.
- Tests added/adjusted for dealer-button placement (varied labels) and
  folded-player seat-retention/card-removal.
- Manual check against real hands (a fold; a non-standard button label).
