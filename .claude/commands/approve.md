# /approve

Validate and approve a spec, plan, or slice map and advance the lifecycle gate.

## Usage
/approve <target> [--stage slices] [--reviewer <name>] [--force]

## Behavior

### Spec+Plan Mode (default)
1. Locate `specs/*/<target>/<target>.spec.md` and `.plan.md`
2. Verify spec `status: specified` — halt if not (unless `--force`)
3. Check for `### UNRESOLVED:` markers — halt if found (unless `--force`)
4. Set spec frontmatter `status: planned`
5. Set plan frontmatter `status: approved`
6. Call `/update-gate <target> planned` — unless the gate entry already reads `planned` (e.g. re-approval after a rollback), in which case skip this call (it would be rejected as a non-forward step). The frontmatter/plan writes above remain idempotent.

### Slice Map Mode (`--stage slices`)
1. Locate `specs/planning/<target>-slices/<target>-slices.spec.md`
2. Verify slice map `status: draft`
3. Validate sizing limits on ALL slices:
   - ≤15 files modified
   - ≤2 modules touched
   - ≤7 acceptance criteria
   - ≤500 LOC estimated
4. If all pass: set `status: approved`
5. If any fail: halt with violations listed

## Reads
- `specs/*/<target>/<target>.spec.md`
- `specs/*/<target>/<target>.plan.md`
- `specs/planning/<target>-slices/<target>-slices.spec.md`

## Writes
- Spec frontmatter: `specified` → `planned`
- Plan frontmatter: `not_started` → `approved`
- Slice map: `draft` → `approved`
- `project/gate-status.yaml` (via `/update-gate`)

## Delegates To
- `/update-gate`
