---
type: runbook
status: active
---

# Onboard Repo Runbook

Step-by-step guide to bring any repository from zero to loop-ready.

## Path A: New Repo from Template

1. **Propose**: `/register-repo --status proposed`
2. **Approve**: Architecture review → `/promote-repo planned`
3. **Scaffold**: `/scaffold-repo <name> --template <nestjs|nextjs|worker>`
4. **Verify**: `/repo-status repos/<name>`

## Path B: Existing Repo

1. **Register**: `/register-repo <org/name> --status active`
2. **Clone**: `git clone <url> repos/<name>`
3. **Initialize**: `/init-repo repos/<name> --framework jest --gate-level minimal`
4. **Fix issues**: Address any validation failures
5. **Verify**: `/repo-status repos/<name>`

## What `/init-repo` Does

```
Step A: generate-loop-config.sh → _loop-config.yaml
Step B: validate-loop-config.sh → schema check
Step C: Harness Init            → CLAUDE.md + AGENTS.md setup
Step D: CI check                → Advisory
```

Result: READY (all A–D pass) or NOT READY (with failure details).

## Troubleshooting

### `_loop-config.yaml` validation fails
- Check `test.framework` is one of: jest, vitest, mocha, pytest, go-test
- Check `gates.default_level` is one of: minimal, standard, full
- Ensure `compliance.rules` includes ALL of: SEC-001, SEC-002, PLAT-001
- Run: `./scripts/validate-loop-config.sh repos/<name>/_loop-config.yaml`

### Health endpoint missing
- Required for `standard` and `full` gate levels
- Add `/health` or `/healthz` endpoint returning 200

### Observability SDK not detected
- Required for `standard` and `full` gate levels
- Check platform requirements for exact expectations

### CI not green
- Advisory only — does not block `/init-repo`
- Fix before dispatching `/multi-repo-loop` with `--gates standard` or higher

### CLAUDE.md not generated
- `/init-repo` Step C must create this file
- If missing after init, create minimal CLAUDE.md pointing to AGENTS.md manually

## Template Types

Adapt these per your stack:
- `nestjs-api` — Backend API service
- `nextjs-app` — Frontend web application
- `nestjs-workers` — Background job processors
- `migration` — Database migration service

## Key Convention

All repos live at `repos/<name>/` — this is a hard convention that scripts depend on.
Platform compliance is a gate before loop dispatch.
