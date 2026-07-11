# Cross-repo plan — replayer-display-fixes

**Spec:** `specs/bug/replayer-display-fixes/replayer-display-fixes.spec.md`
**Type:** bug · **Quality gate:** standard

## Scope

Presentation-only fixes to the hand replayer poker table. Single repo:

| Order | Repo | Rationale |
|-------|------|-----------|
| 1 | `lolfold-frontend` | Only affected repo. All four fixes live in `src/components/replayer/PokerTable.tsx`. No API/infra changes. |

No `depends_on`; no cross-repo contracts. Serialized dispatch is a single sub-agent.

## Work (delegated to `/multi-repo-loop lolfold-frontend --gates standard`)

The sub-agent owns planning, TDD execution, adversarial review, and PR submission for the four bugs:

1. Every player seat stays visible for the whole hand (no seat vanishes).
2. A player's cards are removed on fold; seat persists.
3. Dealer button always renders at the correct seat, robust to position-label variants.
4. A player's two cards render adjacent (side by side), not flanking the seat.

Acceptance and test guidance per the spec. Build/test/typecheck gates: `npm run build`, `npm run test:run`, `npx tsc -b --noEmit`.

## Gate schedule (standard)

- spec-review: skip
- plan-review: **PAUSE** (this gate)
- pr-review: **PAUSE** (after companion PR opens)
- spec-complete: skip → archive on merge decision
