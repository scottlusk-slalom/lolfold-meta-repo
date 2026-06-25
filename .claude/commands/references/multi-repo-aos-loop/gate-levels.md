# Gate Levels Reference

Runtime behavior for each gate level, consumed by `/multi-repo-aos-loop` and enforced by `validate-loop-config.sh`.

## Enum Values (authoritative)

These three values are the exact enum for `_loop-config.yaml` `gates.default_level` and `gates.overrides.*`.

| Level | Test Failures | Dependency Scan | SAST | Coverage | E2E |
|-------|--------------|-----------------|------|----------|-----|
| `minimal` | Stop (3 retries) | Skip | Skip | Skip | Advisory |
| `standard` | Stop (3 retries) | Stop on critical/high | Advisory | Skip | Block |
| `full` | Stop (any) | Stop on any finding | Gate failure stops | < 80% stops | Block |

## Detailed Behavior

### `minimal`
- Stop only on test failures (3 retries before halt)
- Skip dependency-scan and SAST scans entirely
- E2E test failures are advisory (logged, not blocking)

### `standard`
- Stop on test failures (3 retries before halt)
- Stop on dependency-scan findings rated critical or high
- SAST findings are advisory (logged, not blocking)
- E2E test failures block

### `full`
- Stop on ANY test failure (no retries tolerance)
- Stop on ANY dependency-scan finding (any severity)
- SAST gate failure stops execution
- Coverage below 80% stops execution
- E2E test failures block

## Important
- `--strict` is a SEPARATE boolean flag (not a gate level)
- `--strict` means: halt the entire multi-repo run if any repo fails pre-flight
- Gate levels control per-repo enforcement; `--strict` controls run-level behavior
