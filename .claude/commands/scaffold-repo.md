# /scaffold-repo

Create a new repo from a template on GitHub, clone it locally, and chain `/init-repo`.

## Usage
/scaffold-repo <name> --template <nestjs|nextjs|worker> [--dry-run] [--skip-init]

## Behavior

1. **Validate**:
   - Name matches `^[a-z0-9][a-z0-9-]*[a-z0-9]$` and ≤25 chars
   - Repo must be registered in `project/project-repositories.yaml` with `status: planned` or `active`
   - Halt if GitHub repo already exists (check via `gh repo view`)

2. **Create** from template:
   - `gh repo create ${GITHUB_ORG}/<name> --template ${GITHUB_ORG}/<template>-template --public`

3. **Clone** to `repos/<name>/`

4. **Update registry**:
   - Set `status: active`, `onboarded: <today>`
   - Fill `git.*` fields and `local_path: repos/<name>`

5. **Validate**: Run `./scripts/validate-repos-yaml.sh`

6. **Initialize** (unless `--skip-init`):
   - Call `/init-repo repos/<name>`
   - Do NOT abort on `/init-repo` failure — capture and report

## Reads
- `project/project-repositories.yaml`

## Writes
- `repos/<name>/` (cloned repo)
- `project/project-repositories.yaml`

## Delegates To
- `./scripts/validate-repos-yaml.sh`
- `/init-repo`
