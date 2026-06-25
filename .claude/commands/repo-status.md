# /repo-status

Dashboard of all repos by lifecycle state, or loop-readiness check on a specific repo.

## Usage
/repo-status [filter | repo-path]

Filters: `proposed | planned | active | archived | legacy | all`
If a path is given instead, triggers readiness check mode.

## Behavior

### Dashboard Mode (filter or no args)
1. Read `project/project-repositories.yaml`
2. Read `project/gate-status.yaml` for active spec counts per repo
3. Display table grouped by status:
   ```
   ## Active (3)
   | Repo | Gate Level | Specs In-Flight | Last Activity |
   |------|-----------|-----------------|---------------|
   ```
4. Show next-command suggestion per repo based on current state

### Readiness Check Mode (path given)
1. Check `_loop-config.yaml` exists and is valid
2. Check `CLAUDE.md` exists
3. Check `AGENTS.md` exists
4. Run `./scripts/validate-gp.sh <path>`
5. Report pass/fail per check
6. Exit 0 if all pass, 1 otherwise

## Reads
- `project/project-repositories.yaml`
- `project/gate-status.yaml`
- `<path>/_loop-config.yaml`
- `<path>/CLAUDE.md`

## Writes
- Nothing (read-only)

## Notes
- Never halts — reports errors inline
