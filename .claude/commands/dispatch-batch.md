# /dispatch-batch

Full pipeline from planning spec to executed slices: analyze → decompose → generate feature specs → dispatch loops per step.

## Usage
/dispatch-batch <planning-spec-id> --steps <A,B,...> [--dry-run] [--skip-analysis] [--skip-decompose] [--skip-generate] [--gates <minimal|standard|full>]

Default `--gates`: `minimal`

## Behavior

### Phase 1: Context Analysis (unless `--skip-analysis`)
- Invoke `context-curator` agent on `specs/planning/<id>/`
- Invoke `legacy-analyzer` agent
- Output: `specs/planning/<id>/context/CONTEXT.md`, `context/*-analysis.md`

### Phase 2: Decomposition (unless `--skip-decompose`)
- Invoke `slice-decomposer` agent
- Output: `<id>-slices.spec.md`

### Phase 3: Approval Gate
- Require slice map `status: approved` before proceeding
- Halt on `⚠️ DESIGN DECISION REQUIRED` markers

### Phase 4: Generate Feature Specs (unless `--skip-generate`)
- For each slice in the specified `--steps`:
  - Call `/generate-spec <slice-id> --type feature --skip-curator`
  - Each produces `specs/feature/<id>/<slice>/` with `status: specified`

### Phase 5: Dispatch Execution
- For each step (A, B, C…) in order:
  - ALL slices in step A must complete before step B starts
  - Within a step: slices targeting different modules may run parallel
  - Within a step: slices targeting same files must run sequential
  - Call `/multi-repo-loop <slice-id> --gates <level>` per slice

### Phase 6: Tracking
- Update `specs/planning/<id>/status.md`
- Update `project/gate-status.yaml`
- Commit: `chore(<id>): batch results — N/M slices pass`

## Reads
- `specs/planning/<id>/`
- `specs/planning/<id>/context/requirements.md`
- `architecture/context-index.md`
- `architecture/legacy/service_inventory.md`
- `architecture/legacy/integration_map.md`
- `project/gate-status.yaml`

## Writes
- `specs/planning/<id>/context/CONTEXT.md`
- `specs/planning/<id>/context/*-analysis.md`
- `<id>-slices.spec.md`
- `specs/feature/<id>/*/` (feature spec dirs)
- `specs/planning/<id>/status.md`
- `project/gate-status.yaml`

## Delegates To
- `context-curator` agent
- `legacy-analyzer` agent
- `slice-decomposer` agent
- `/generate-spec`
- `/multi-repo-loop`
