# /archive-spec

Archive a completed spec with memory promotion, cleanup, and dependency-graph update.

## Usage
/archive-spec

Infers spec from current working directory, or prompts via `/list-specs`.

## Behavior

1. Identify spec to archive (from CWD or interactive selection)
2. Verify gate status is `submitted` — warn if not
3. Update spec frontmatter: `status: archived`, `archived_date: <today>`
4. Append `## Archive Summary` section to spec with:
   - Completion date
   - PRs created
   - Key decisions made
5. If `architecture/legacy/dependency-graph.yaml` exists, update:
   - `replacing_specs` list
   - `replacement_status`
   - `decommission_blocked_by`
6. Commit: `chore: archive spec <spec-name>`

## Reads
- `project/gate-status.yaml`
- `specs/*/<spec-id>/context/scratch/`
- `architecture/legacy/dependency-graph.yaml`
- `project/project-repositories.yaml`

## Writes
- Spec frontmatter: `status: archived`, `archived_date`
- `architecture/legacy/dependency-graph.yaml`
- Appends `## Archive Summary` to spec

## Notes
- If `dependency-graph.yaml` is missing, warn and skip that step
