# Execution Plan: bug/default-blinds-fix

## Summary

Single-repo fix in `lolfold-api`. Change default blinds from 1/2 to 2/5 when the parser cannot infer blind sizes.

## Repo: lolfold-api

### Tasks

1. **Modify `src/services/hand.ts`** — Change fallback blinds object from `{ "small": 1, "big": 2 }` to `{ "small": 2, "big": 5 }`.
2. **Update validation warning message** — Change text from "defaulted to 1/2" to "defaulted to 2/5".
3. **Update tests** — Any test expecting the old default (1/2) must be updated to expect 2/5. Tests that explicitly set blinds remain unchanged.

### Execution Order

Single repo, no dependencies. One dispatch to `lolfold-api`.

### Branch

`agent/bug/default-blinds-fix`
