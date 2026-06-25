# /init-repo

Take a cloned repo from zero to loop-ready.

## Usage
/init-repo <path> [--framework <jest|vitest|mocha|pytest|go-test>] [--gate-level <minimal|standard|full>] [--skip-gp] [--force]

## Behavior

### Step A: Generate Loop Config
- Run `./scripts/generate-loop-config.sh --target <path>` with framework and gate-level flags
- This creates `<path>/_loop-config.yaml` and validates it

### Step B: Validate Loop Config
- Run `./scripts/validate-loop-config.sh <path>/_loop-config.yaml`
- Halt if validation fails (unless `--force`)

### Step C: AOS Loop Init
- Run `/aos-loop-init` in the target repo
- Halt if `CLAUDE.md` not created or no `AGENTS.md` exists after this step

### Step D: Golden Path Validation (unless `--skip-gp`)
- Run `./scripts/validate-gp.sh <path>`
- GP failures are ADVISORY — continue regardless, but report findings

### Step E: CI Check (advisory)
- Check if CI config exists and is valid
- Advisory only — continue regardless

## Result
- READY: all steps A–D pass
- NOT READY: report which steps failed

## Reads
- `<path>/_loop-config.yaml`
- `<path>/AGENTS.md`
- `<path>/package.json`
- `<path>/playwright.config.*`

## Writes
- `<path>/_loop-config.yaml`
- `<path>/CLAUDE.md`
- `<path>/AGENTS.md` (appends `## Testing Strategy`)

## Delegates To
- `./scripts/generate-loop-config.sh`
- `./scripts/validate-loop-config.sh`
- `/aos-loop-init`
- `./scripts/validate-gp.sh`
