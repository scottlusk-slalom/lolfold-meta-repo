---
name: e2e-tdd-playwright
applies_when:
  loop_config:
    test.e2e_framework: playwright
    test.e2e_tdd: true
  spec_section: "## UI Test IDs"
skip_when:
  spec_tags_any: [api-only, worker, migration]
requires:
  - playwright
  - dev-server
injects_into: execute
---

# E2E TDD with Playwright

Browser test TDD instructions for UI specs.

## Flow

1. **Kill stale dev server** — ensure no prior instance blocks the port
2. **Write test file** — `<feature>.e2e-spec.ts` with failing assertions
3. **API mocking** — set up route handlers for:
   - Success path (200 + expected payload)
   - Error path (4xx/5xx + error state)
   - Loading state (delayed response)
4. **RED** — run test, confirm it fails for the right reason
5. **Implement** — build the component/page until test passes
6. **GREEN** — all assertions pass
7. **Regression check** — run full e2e suite, no new failures

## Patterns by Component Type

| Component | Test Focus |
|-----------|-----------|
| Form | Validation states, submission, error display |
| List/Table | Empty state, loading, populated, pagination |
| Modal/Dialog | Open/close, form within, escape handling |
| Navigation | Route changes, active states, breadcrumbs |

## Test ID Attribute

Use `data-testid` attributes for stable selectors. If your component library uses a different attribute (e.g., `data-test`), configure:

```typescript
// playwright.config.ts
use: {
  testIdAttribute: 'data-testid', // adapt to <your component library>
}
```

## Negative Tests

Every happy-path test needs a corresponding error test:
- Network failure → error state rendered
- Validation failure → inline errors shown
- Auth failure → redirect to login

## Timing

- Use `waitForSelector` or Playwright auto-wait — never `setTimeout`
- For animations: `waitForFunction` with stability check
- For API calls: wait for network idle or specific response
