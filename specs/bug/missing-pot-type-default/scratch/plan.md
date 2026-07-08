# Execution Plan: Default potType to single_raised when not determinable

## Scope
Single-repo bug fix. No cross-repo dependencies, no companion PRs.

## Repo: lolfold-api

### Tasks
1. In `src/services/hand.ts`, locate the system prompt rule 9 describing `potType`.
2. Add fallback instruction to rule 9: "If pot type cannot be determined from
   preflop action, default to single_raised."
3. Update the confidence flags example in the same prompt to demonstrate the
   defaulted case:
   `{ "field": "potType", "issue": "Pot type not determinable from action, defaulted to single_raised" }`

### TDD
- Add/extend a test asserting that when preflop action is indeterminate, the
  parser output has `potType === "single_raised"` and a matching confidence flag.
- Add/verify a test that hands with determinable potType are unchanged (no
  spurious confidence flag, correct potType).

### Verification gates (must all pass before PR)
- `npm run build` exits 0
- `npm test` exits 0
- `npx tsc --noEmit` exits 0

### Acceptance criteria (from SPEC.md)
- potType defaults to `single_raised` when not determinable from preflop action
- A confidence flag is added when the default is used
- Hands where potType IS determinable remain unaffected

## Integration points
None. Prompt-only + test change within lolfold-api.

## Execution order
Single repo — no ordering required.
