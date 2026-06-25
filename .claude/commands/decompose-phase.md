# /decompose-phase

Break an engineering plan phase into right-sized, independently shippable slices.

## Usage
/decompose-phase <phase-name-or-number> [--dry-run] [--refresh]

## Behavior

1. **Locate phase** in `project/engineering-plan.md` by name or number
2. **Halt** if output exists at `specs/planning/<PHASE_SLUG>-slices/` without `--refresh`
3. **Validate required inputs**:
   - `project/engineering-plan.md` (required)
   - `architecture/legacy/service_inventory.md` (required)
   - `architecture/legacy/integration_map.md` (required)
   - `architecture/legacy/data_model.md` (conditional — if data layer phase)
4. **Invoke** `.claude/agents/slice-decomposer.md`
5. **Validate output** against sizing limits:
   - ≤15 files modified per slice
   - ≤2 modules touched per slice
   - ≤7 acceptance criteria per slice
   - ≤500 LOC estimated per slice
   - No dependency cycles between slices
   - All phase deliverables covered
6. **Set status**:
   - `approved` if ALL sizing checks pass
   - `draft` if ANY fail (with violations listed)

## Output
`specs/planning/<PHASE_SLUG>-slices/<PHASE_SLUG>-slices.spec.md` with:
- YAML frontmatter: `type: planning`, `status: draft|approved`
- Summary table of all slices
- Per-slice detail blocks with parallel step assignments (A, B, C…)

## Reads
- `project/engineering-plan.md`
- `architecture/legacy/service_inventory.md`
- `architecture/legacy/integration_map.md`
- `architecture/legacy/data_model.md` (conditional)

## Writes
- `specs/planning/<PHASE_SLUG>-slices/<PHASE_SLUG>-slices.spec.md`

## Delegates To
- `.claude/agents/slice-decomposer.md`
