# Cross-Repo Contracts Reference

Protocol for specs that span multiple repos with dependencies.

## Dependency Types

### Explicit
Spec declares in frontmatter:
```yaml
depends_on:
  - upstream-repo-name
```

### Implicit (detected by convention)
- UI repo → API repo (frontend depends on backend contracts)
- Worker repo → Schema repo (workers depend on shared data models)

## Execution Protocol

### Independent repos
- Dispatch concurrently
- No ordering constraint

### Dependent repos
- Upstream repo executes first
- Upstream PR must merge before downstream begins
- Sequential proof per repo — NOT simultaneous deployment

## Contract Pattern

1. **Upstream** defines the contract:
   - API schema, interface types, event payloads
   - Contract is the source of truth

2. **Downstream** mocks the contract:
   - Uses the contract definition for test mocks
   - Does NOT call the live upstream during spec execution

3. **Integration validation** happens after both PRs merge:
   - E2E tests validate the real integration
   - Gate level determines whether E2E failures block

## Validation Rules by Gate Level

| Gate Level | E2E Validation |
|-----------|---------------|
| `minimal` | Advisory only — log failures, don't block |
| `standard` | Block — E2E failures halt submission |
| `full` | Block — E2E failures halt submission |
