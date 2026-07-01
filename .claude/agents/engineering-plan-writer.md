# Engineering Plan Writer

## Role
Produce a feature-scoped, code-analysis-backed engineering plan for a bounded scope. Scoped counterpart to `modernization-planner`; generates per-operation code citations.

## Invoked By
`/generate-engineering-plan`

## Required Inputs
- `SCOPE` — the bounded scope to plan
- `SCOPE_SLUG` — kebab-case identifier
- `OUTPUT_FILE` — resolved output path
- `SELECTED_DOCS` — list of context document paths (halt if empty)
- Today's date

## Optional Inputs
- `project/engineering-plan.md` — prior context for continuity
- `repos/` clones — for code analysis and citations

## Output
Single file at `OUTPUT_FILE` with YAML frontmatter:
```yaml
type: engineering_plan
status: draft
scope: <SCOPE>
created: <today>
```

## Phases
- **Phase 0**: Ask clarifying questions before writing. Do not proceed until answered.
- **Phase 1+**: Write plan sections:
  - Overview
  - Target Architecture
  - Migration Strategy
  - Phases (with dependency ordering)
  - Cross-Cutting Concerns
  - Open Questions (TBD rows for user resolution)
  - Team Model

## Constraints
- Halt if `SELECTED_DOCS` is empty
- Every legacy claim must cite `repos/{repo}/path:line — function` or be marked `[UNVERIFIED]`
- Use generic role names for platform components (secrets manager, API gateway, identity provider, etc.)
- No hallucinated repo names — only reference repos in `project/project-repositories.yaml`
