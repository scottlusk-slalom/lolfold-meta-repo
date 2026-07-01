# /plan-impl

Generate an implementation plan from a staged spec. Replaces the legacy external toolkit.

## Usage
/plan-impl [--spec-dir <path>]

If `--spec-dir` omitted, infer from current working directory (expects to be in a worktree's `_working/<key>/` or the worktree root).

## Behavior

1. **Locate context** in `_working/<key>/`:
   - `spec.md` (required — halt if missing)
   - `codebase-analysis.md` (optional)
   - `decisions.md` (optional)
   - `context/` directory (optional)

2. **Analyze the spec**:
   - Parse acceptance criteria
   - Identify affected modules/files from the spec
   - Map dependencies between ACs

3. **Scan the repo**:
   - Read `CLAUDE.md` and `AGENTS.md` for project conventions
   - Read `_loop-config.yaml` for test framework and topology
   - Identify existing patterns in the codebase relevant to the spec

4. **Generate plan** at `_working/<key>/impl-plan.md`:
   - Ordered task list (each task is one TDD cycle)
   - Per task: files to create/modify, test approach, AC traceability
   - Dependency ordering (which tasks must complete before others)
   - Risk flags (complex integrations, data migrations, etc.)

5. **Validate plan**:
   - Every AC must be covered by at least one task
   - No circular task dependencies
   - Task granularity: each task should be completable in one RED/GREEN/Refactor cycle

## Output Format
```markdown
# Implementation Plan — <spec-key>

## Tasks

### Task 1: <title>
- **AC**: (ref: REQ-N or AC number)
- **Files**: <list of files to create/modify>
- **Test**: <test file and approach>
- **Depends on**: (none or task numbers)

### Task 2: ...
```

## Reads
- `_working/<key>/spec.md`
- `_working/<key>/codebase-analysis.md`
- `_working/<key>/decisions.md`
- `CLAUDE.md`, `AGENTS.md`
- `_loop-config.yaml`

## Writes
- `_working/<key>/impl-plan.md`

## Retry Policy
0 retries. If plan generation fails, halt and report.
