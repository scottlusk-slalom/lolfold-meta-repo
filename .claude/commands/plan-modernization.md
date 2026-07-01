# /plan-modernization

Invoke the modernization-planner agent to produce an executive readout and phased engineering plan.

## Usage
/plan-modernization [--dry-run] [--refresh]

## Behavior

1. **Validate inputs** — ALL three required, halt if any missing:
   - `architecture/legacy/service_inventory.md`
   - `architecture/legacy/integration_map.md`
   - `project/product-brief.md`

2. **Check outputs** — halt if either exists without `--refresh`:
   - `project/executive-readout.md`
   - `project/engineering-plan.md`

3. **Invoke** `.claude/agents/modernization-planner.md` with the three inputs

4. **Validate** both outputs are non-empty after agent run

## Reads
- `architecture/legacy/service_inventory.md`
- `architecture/legacy/integration_map.md`
- `project/product-brief.md`

## Writes
- `project/executive-readout.md`
- `project/engineering-plan.md`

## Delegates To
- `.claude/agents/modernization-planner.md`
