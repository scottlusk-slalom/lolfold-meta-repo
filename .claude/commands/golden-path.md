# /golden-path

Validate a repository against Golden Path platform requirements or sync the GP cache.

## Usage
/golden-path [<repo-path>] [--sync] [--check-only]

## Behavior

### Validate Mode (default, with repo-path)
1. Run `./scripts/validate-gp.sh <repo-path>`
2. Report results grouped by category with pass/fail/skip per rule
3. Suggest remediation for failures

### Sync Mode (`--sync`)
1. Run `./scripts/sync-gp.sh`
2. Report new lines found in platform handbook not yet in `org/golden-path/requirements.md`
3. Do NOT auto-edit — human curates

### Check Mode (`--check-only`)
1. Run `./scripts/sync-gp.sh --check-only`
2. Exit 0 if cache is current
3. Exit 1 if stale (per `org/cache.yaml` `stale_after_days`)

## Reads
- `org/golden-path/gp-rules.json`
- `org/golden-path/requirements.md`
- `org/cache.yaml`

## Writes
- Nothing in validate/check mode
- `org/cache.yaml` timestamps (sync mode only, via `sync-gp.sh`)

## Delegates To
- `./scripts/validate-gp.sh`
- `./scripts/sync-gp.sh`
