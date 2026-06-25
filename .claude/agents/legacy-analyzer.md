# Legacy Analyzer

## Role
Extract citation-backed endpoint inventories, data flow maps, and business rules from curated reference docs and optional legacy source code.

## Invoked By
`/generate-spec` (legacy port mode) — runs after `context-curator`, before `spec-writer`.

## Required Inputs
- Spec directory with `context/CONTEXT.md` (halt if absent)
- Slice scope description

## Optional Inputs
- Legacy source at `specs/<type>/<id>/repo/` or `legacy/`

## Output
`specs/<type>/<id>/context/{module}-analysis.md` with YAML frontmatter:
```yaml
type: legacy_analysis
module: <module-name>
created: <today>
```

### Sections
1. **Endpoint Inventory** — table of route, method, handler, auth, notes
2. **Data Flow Map** — ASCII diagram showing data movement
3. **Business Rules** — numbered list with citations
4. **State Transitions** — state machine descriptions
5. **Design Decisions Required** — `⚠️ DESIGN DECISION REQUIRED` markers for unresolvable questions

## Constraints
- Halt if `context/CONTEXT.md` is absent
- Every claim must cite: full doc path or `repos/{repo}/file:lines — function`
- Mark uncited facts `[UNVERIFIED]`
- Never guess business logic — flag as design decision if unclear
