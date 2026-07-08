# Execution Plan: Default potType to single_raised

## Repos

1. `lolfold-api` (only repo)

## Tasks: lolfold-api

1. Open `src/services/hand.ts`
2. Locate the system prompt section where potType is described (rule 9)
3. Add fallback instruction: "If pot type cannot be determined from preflop action, default to single_raised."
4. Update the confidence flags example to show the defaulting case: `{ "field": "potType", "issue": "Pot type not determinable from action, defaulted to single_raised" }`
5. Verify existing potType determination logic remains unaffected

## Acceptance Criteria

- potType defaults to `single_raised` when not determinable
- Confidence flag added when default is used
- Existing determinable cases unaffected

## Dependency Order

N/A — single repo.
