# /discover-specs

Analyze project context and produce a prioritized spec backlog — a menu of spec candidates you can cherry-pick from when ready to `/generate-spec`. Does NOT create any specs or files beyond its own output.

## Usage
/discover-specs [--output <path>] [--focus <theme>]

- `--output <path>` — Write results to a file (default: print to conversation)
- `--focus <theme>` — Narrow discovery to a single theme from the project plan

## Behavior

### Step 1: Load Project Context

Read the following files (skip any that don't exist):
- `project/product-brief.md`
- `project/project-plan.md`
- `project/project-repositories.yaml`
- `architecture/context-index.md`
- `AGENTS.md` (header block only)

If none of these exist, halt with: "No project context found. Run `/scaffold-project` first."

### Step 2: Identify Themes

Extract themes/objectives from `project-plan.md`. If no plan exists, derive themes from the product brief's core capabilities.

### Step 3: Decompose Into Spec Candidates

For each theme, produce spec candidates following these principles:

1. **Vertical slices** — each candidate should be independently deployable and testable
2. **Small scope** — a single spec should take 5-30 minutes to execute via `/execute-impl`
3. **Clear boundaries** — no overlapping scope between candidates
4. **Dependency-aware** — mark which candidates must come before others

For each candidate, determine:
- **id** — kebab-case slug suitable for `/generate-spec <id>`
- **type** — feature | bug | chore | design | planning
- **brief** — one-line description specific enough for good requirements generation (include HTTP methods, data shapes, or UI elements where applicable)
- **repos** — which repos from `project-repositories.yaml` this touches
- **depends-on** — list of candidate IDs that must be completed first (empty if independent)
- **priority** — P0 (pipeline validation), P1 (core functionality), P2 (enhancement), P3 (nice-to-have)

### Step 4: Order Into Phases

Group candidates into recommended execution phases:

- **Phase 0: Pipeline Validation** — Health endpoints, CI verification, basic connectivity. Proves the pipeline works.
- **Phase 1: Foundation** — Data models, auth, core middleware. Everything else depends on these.
- **Phase 2: Core Features** — Primary user-facing functionality.
- **Phase 3: Integration** — Cross-service communication, event handling, external APIs.
- **Phase 4: Polish** — Error handling improvements, logging, monitoring, performance.

Not all phases need candidates. Skip empty phases.

### Step 5: Present Results

Output format:

```markdown
# Spec Discovery: <Project Name>

Generated: <date>
Themes analyzed: <count>
Candidates identified: <count>

## Phase 0: Pipeline Validation

| # | ID | Type | Brief | Repos | Depends On |
|---|-----|------|-------|-------|------------|
| 1 | health-endpoint | feature | Add GET /health returning 200 with service name and version | my-api | — |

## Phase 1: Foundation
...

## Recommended Starting Point

Start with: `<id>` — <why this is the best first spec>

Quick start:
\```
/generate-spec <id> "<brief>" --type <type>
\```

## Notes

- <any assumptions made during decomposition>
- <any gaps where human judgment is needed>
```

### Step 6: Offer Refinement

After presenting, ask:
```
Want me to:
- Drill deeper into a specific phase or theme?
- Adjust scope (smaller/larger slices)?
- Add candidates for something not covered?
- Run `/generate-spec` for any of these now?
```

## Reads
- `project/product-brief.md`
- `project/project-plan.md`
- `project/project-repositories.yaml`
- `architecture/context-index.md`
- `AGENTS.md`
- `specs/` (to check what specs already exist and exclude them)

## Writes
- Only if `--output` is specified: writes to the given path

## Halt Conditions
- No project context files exist (product-brief, project-plan, or AGENTS.md with filled header)

## Design Principles

- **Read-only by default** — never creates specs, repos, or modifies project files
- **Opinionated ordering** — gives a clear "start here" recommendation, not just a flat list
- **Brief quality matters** — briefs must be specific enough to pass directly to `/generate-spec` without editing
- **Respects existing work** — checks `specs/` directory and excludes already-created specs from the output
- **Re-runnable** — safe to run multiple times as the plan evolves; output reflects current state
