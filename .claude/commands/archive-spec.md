# /archive-spec

Archive a completed spec with memory promotion, cleanup, and dependency-graph update.

## Usage
/archive-spec [--force]

Infers spec from current working directory, or prompts via `/list-specs`. `--force` bypasses the `submitted` precondition AND forces the gate write (`/update-gate <spec-id> archived --force`).

## Behavior

1. Identify spec to archive (from CWD or interactive selection)
2. Verify gate status is `submitted` — HALT if not (archival is only legal from `submitted`; step 5's `/update-gate archived` would otherwise be a rejected multi-step jump). Override with `--force` only if you also intend to force the gate write.
3. Update spec frontmatter: `status: archived`, `archived_date: <today>`
4. Append `## Archive Summary` section to spec with:
   - Completion date
   - PRs created
   - Key decisions made
5. Call `/update-gate <spec-id> archived` so `gate-status.yaml` matches the spec frontmatter (otherwise the gate stays at `submitted` while the spec reads `archived` — state divergence).
6. If `architecture/legacy/dependency-graph.yaml` exists, update:
   - `replacing_specs` list
   - `replacement_status`
   - `decommission_blocked_by`
7. Commit: `chore: archive spec <spec-name>`

## Reads
- `project/gate-status.yaml`
- `specs/*/<spec-id>/context/scratch/`
- `architecture/legacy/dependency-graph.yaml`
- `project/project-repositories.yaml`

## Writes
- Spec frontmatter: `status: archived`, `archived_date`
- `project/gate-status.yaml` (via `/update-gate <spec-id> archived`)
- `architecture/legacy/dependency-graph.yaml`
- Appends `## Archive Summary` to spec

## Delegates To
- `/update-gate`

## Notes
- If `dependency-graph.yaml` is missing, warn and skip that step
