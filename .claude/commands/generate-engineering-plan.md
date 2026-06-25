# /generate-engineering-plan

Invoke the engineering-plan-writer agent to produce a scoped, code-analysis-backed engineering plan.

## Usage
/generate-engineering-plan <scope> [--output <path>] [--refresh]

## Behavior

1. **Resolve output path**: `project/<scope-slug>-engineering-plan.md` (or `--output`)
2. **Halt** if output exists without `--refresh`
3. **Gather context**:
   - `project/product-brief.md`
   - `project/project-plan.md`
   - `architecture/context-index.md`
   - `architecture/legacy/service_inventory.md`
   - `architecture/legacy/integration_map.md`
   - `org/golden-path/requirements.md`
   - `project/engineering-plan.md` (if exists, as prior context)
   - `repos/` (for code analysis)

4. **Invoke** `engineering-plan-writer` agent with:
   - `SCOPE`: the scope argument
   - `SCOPE_SLUG`: kebab-case version
   - `OUTPUT_FILE`: resolved output path
   - `SELECTED_DOCS`: gathered context paths
   - Today's date

5. **Validate output**:
   - Frontmatter must have `type: engineering_plan`, `status: draft`
   - No hallucinated repo names (cross-check against `project/project-repositories.yaml`)
   - Surface Open Questions gate for user resolution

## Reads
- `project/product-brief.md`, `project/project-plan.md`
- `architecture/context-index.md`
- `architecture/legacy/service_inventory.md`, `architecture/legacy/integration_map.md`
- `org/golden-path/requirements.md`
- `project/engineering-plan.md`
- `repos/`

## Writes
- `project/<scope-slug>-engineering-plan.md`

## Delegates To
- `.claude/agents/engineering-plan-writer.md`
