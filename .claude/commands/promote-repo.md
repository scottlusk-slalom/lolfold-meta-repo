# /promote-repo

Move a repository through lifecycle gates.

## Usage
/promote-repo [repo-name] [target-status]

## Allowed Transitions
- `proposed` → `planned`
- `planned` → `active`
- `active` → `archived`

Any other transition is rejected.

## Behavior

1. Read `project/project-repositories.yaml`, find the repo entry
2. Validate the transition is allowed
3. For `planned → active`:
   - Verify repo exists on GitHub via `gh repo view`
4. For `active → archived`:
   - Check `specs/**/*.spec.md` for active references to this repo
   - Abort if any non-completed specs reference it
5. Update `status` field and move entry to appropriate section
6. Update `selection_guidelines` if needed
7. Run `./scripts/validate-repos-yaml.sh` — revert on failure
8. Run `./scripts/validate-repo-lifecycle.sh` — revert on failure

## Reads
- `project/project-repositories.yaml`
- `specs/**/*.spec.md` (archival check)

## Writes
- `project/project-repositories.yaml`

## Delegates To
- `./scripts/validate-repos-yaml.sh`
- `./scripts/validate-repo-lifecycle.sh`
- `gh repo view` (planned→active)
