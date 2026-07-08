# Execution Plan: Default potType to single_raised when not determinable

## Repos
- lolfold-api (only)

## Dependency order
Single repo — no cross-repo ordering.

## lolfold-api tasks
1. Locate `src/services/hand.ts`, find the system prompt rule 9 describing `potType`.
2. Add fallback instruction to rule 9: "If pot type cannot be determined from
   preflop action, default to single_raised."
3. Update the confidence-flags example in the same prompt to include the
   default case:
   `{ "field": "potType", "issue": "Pot type not determinable from action, defaulted to single_raised" }`
4. Add/adjust tests:
   - A hand with indeterminate preflop action → `potType === "single_raised"` and
     a confidence flag present for `potType`.
   - A hand where potType IS determinable → unchanged (no regression, no spurious flag).

## Acceptance criteria (from SPEC.md)
- potType defaults to `single_raised` when not determinable.
- Confidence flag added when default used.
- Determinable hands unaffected.

## Integration points
None — internal prompt/parsing change. No API contract or schema change.

## Verification gates (pre-submit, all must pass)
- `npm run build`
- `npm test`
- `npx tsc --noEmit`
