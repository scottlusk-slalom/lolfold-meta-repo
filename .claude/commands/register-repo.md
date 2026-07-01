# /register-repo

Add a repository to the project registry in propose mode (new) or onboard mode (existing GitHub repo).

## Usage
/register-repo [org/repo-name | clone-url] [--status <proposed|active>] [--team <name>]

## Behavior

### Propose Mode (no URL argument or --status proposed)
1. Prompt for repo name (kebab-case, ≤25 chars)
2. Insert entry under `# --- Proposed repositories ---` in `project/project-repositories.yaml`
3. Set `status: proposed`, `default_gate_level: minimal`
4. Run `./scripts/validate-repos-yaml.sh` — revert on failure

### Onboard Mode (URL or org/name provided, --status active)
1. Verify repo exists via `gh repo view`
2. Insert entry under `# --- Active repositories ---`
3. Set `status: active`, `onboarded: <today>`
4. Populate `git.*` fields from GitHub API
5. Run `./scripts/validate-repos-yaml.sh` — revert on failure
6. Run `./scripts/validate-repo-lifecycle.sh` — revert on failure

## Validation Rules
- Name must be kebab-case: `^[a-z0-9][a-z0-9-]*[a-z0-9]$`
- Name ≤25 characters
- No duplicate keys in repositories map

## Reads
- `project/project-repositories.yaml`
- GitHub API via `gh` (onboard mode)

## Writes
- `project/project-repositories.yaml`

## Delegates To
- `./scripts/validate-repos-yaml.sh`
- `./scripts/validate-repo-lifecycle.sh`
