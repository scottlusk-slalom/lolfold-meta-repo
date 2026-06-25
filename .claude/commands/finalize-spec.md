# /finalize-spec

Close out a completed spec: archive it, run retrospective, promote learnings.

## Usage
/finalize-spec [<spec-id>] [--phase <name>] [--dry-run]

If `<spec-id>` omitted, infer from current working directory.

## Behavior

1. **Gate Check**: Verify `project/gate-status.yaml` shows `submitted` for this spec.
   - If not `submitted`: warn and ask for confirmation before proceeding.

2. **Retrospective** (inline):
   - Read `specs/*/<spec-id>/context/scratch/` for friction logs, notes
   - Read git diffs and merged PR feedback
   - Identify promotable learnings (patterns, ADRs, contracts)

3. **Promote Context** (requires user confirmation per item):
   - ADRs → `architecture/adr/`
   - Patterns → `architecture/patterns/`
   - Contracts → `architecture/contracts/`
   - Update `architecture/context-index.md`

4. **Archive**:
   - `git mv specs/<type>/<spec-id>/ specs/archive/<spec-id>/`
   - Set spec frontmatter `status: archived`, add `archived_date: <today>`
   - Commit: `chore: archive spec <spec-id>`

5. **Update Gate**:
   - Call `/update-gate <spec-id> archived --force`

6. If patterns promoted, commit: `chore(patterns): promote <topic> pattern from <spec-id> retrospective`

## Reads
- `project/gate-status.yaml`
- `specs/*/<spec-id>/context/scratch/`
- `architecture/legacy/dependency-graph.yaml`
- `playbooks/*.md`
- `architecture/patterns/*.md`
- `architecture/context-index.md`

## Writes
- Spec moved to `specs/archive/`
- Spec frontmatter updated
- `project/gate-status.yaml` (via `/update-gate`)
- `playbooks/*.md` (promoted learnings)
- `architecture/patterns/*.md` (promoted patterns)
- `architecture/context-index.md`

## Delegates To
- `/update-gate`
