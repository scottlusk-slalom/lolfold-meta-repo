# Execution Plan: Default potType to single_raised

## Repos

1. `lolfold-api` (sole repo)

## Tasks — lolfold-api

### 1. Update system prompt in `src/services/hand.ts`

- Locate the system prompt section that describes potType (rule 9)
- Add fallback instruction: "If pot type cannot be determined from preflop action, default to single_raised."
- Update the confidence flags example to include the defaulting case:
  ```json
  { "field": "potType", "issue": "Pot type not determinable from action, defaulted to single_raised" }
  ```

### 2. Add/update tests

- Write a test case where preflop action is incomplete/ambiguous — assert potType = "single_raised"
- Write a test case confirming the confidence flag is present when defaulting
- Verify existing tests still pass (determinable pot types unaffected)

## Dependency Order

Single repo, no dependencies.

## Verification

- `npm run build` passes
- `npm test` passes
- `npx tsc --noEmit` passes
