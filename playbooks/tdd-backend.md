---
name: tdd-backend
applies_when:
  loop_config:
    test.framework: jest
  spec_section: "## API Contract"
skip_when:
  spec_tags_any: [frontend-only, migration]
requires:
  - test-runner   # adapt to your backend framework
  - database
injects_into: execute
---

# TDD Backend

TDD instructions for backend API feature specs.

## Flow

1. **Kill stale server** — ensure no prior test server blocks ports
2. **Write E2E API test** — `<feature>.e2e-spec.ts`:
   - Full HTTP request → response assertion
   - Auth headers included
   - Database state verified after mutation
3. **Write unit tests** — `<module>.spec.ts`:
   - Service layer logic
   - Validation rules
   - Edge cases
4. **RED** — run tests, confirm failures match expected behavior
5. **Implement** — module structure:
   - Controller (thin — delegates to service)
   - Service (business logic)
   - DTO (validation)
   - Entity/Model (if data layer)
6. **GREEN** — all tests pass
7. **Regression** — run full test suite

## Known Friction Points

### Test runner breaking changes
- Check your test runner version compatibility with the project
- Pin versions in `package.json` to avoid surprise upgrades

### Validation library installation
- Some validation libraries require separate installation of transform packages
- Verify decorator/transform support is configured

### Auth guard scope strategy
- Decide: guard at controller level vs. route level
- Document in `context/decisions.md` if spec doesn't specify
- Default: controller level (broader protection)

## Module Structure

```
src/
└── <feature>/
    ├── <feature>.controller.ts
    ├── <feature>.service.ts
    ├── <feature>.module.ts
    ├── dto/
    │   ├── create-<feature>.dto.ts
    │   └── update-<feature>.dto.ts
    └── entities/
        └── <feature>.entity.ts
```
