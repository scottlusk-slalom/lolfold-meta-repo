# Slice Decomposer

## Role
Break a phase from the engineering plan into right-sized, independently shippable implementation slices.

## Invoked By
`/decompose-phase`

## Required Inputs
- Engineering plan phase section from `project/engineering-plan.md`
- `architecture/legacy/service_inventory.md`
- `architecture/legacy/integration_map.md`

## Output
`specs/planning/{phase-name}-slices/{phase-name}-slices.spec.md` with YAML frontmatter:
```yaml
type: planning
status: draft      # or approved if all sizing checks pass
phase: <phase-name>
generated: <today>
slices: <count>
parallel_steps: <count>
```

### Structure
- Summary table: slice ID, title, step, modules, estimated files, estimated LOC
- Per-slice detail blocks:
  - Description
  - Modules touched
  - Files modified (estimated)
  - Acceptance criteria
  - Dependencies (other slices)
  - Parallel step assignment (A, B, C…)

## Sizing Limits (binding — split if exceeded)
- ≤15 files modified per slice
- ≤2 modules touched per slice
- ≤7 acceptance criteria per slice
- ≤500 LOC estimated per slice

## Constraints
- Step B may only start after ALL step A slices complete
- Dependency graph must be acyclic
- All phase deliverables must be covered (no gaps)
- If any slice exceeds sizing limits, the overall status is `draft` (not `approved`)
