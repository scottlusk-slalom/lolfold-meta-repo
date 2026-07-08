# Execution Plan: Default potType to single_raised

## Repos

1. **lolfold-api** (single repo, no dependencies)

## Tasks — lolfold-api

### 1. Update system prompt in `src/services/hand.ts`

- Locate rule 9 (potType description) in the system prompt
- Add fallback instruction: "If pot type cannot be determined from preflop action, default to single_raised."
- Update confidence flags example to include: `{ "field": "potType", "issue": "Pot type not determinable from action, defaulted to single_raised" }`

### 2. Verify existing tests (if any)

- Check if there are existing tests for potType parsing
- Ensure hands where potType IS determinable remain unaffected

## Acceptance Criteria Mapping

| Criteria | Task |
|----------|------|
| potType defaults to single_raised when not determinable | Task 1 |
| Confidence flag added when default used | Task 1 |
| Determinable potType hands unaffected | Task 2 (verification) |

## Execution Order

Single repo — no dependency ordering needed. Execute lolfold-api only.
