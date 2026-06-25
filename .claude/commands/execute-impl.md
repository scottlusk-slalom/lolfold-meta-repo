# /execute-impl

Execute implementation using strict TDD (RED → GREEN → Refactor). Replaces the external `/aos-execute` command.

## Usage
/execute-impl [--spec-dir <path>] [--tasks <1,2,3>]

If `--tasks` omitted, execute all tasks in the implementation plan.

## Behavior

### Context Loading
1. Read `_working/<key>/spec.md` — the spec being implemented
2. Read `_working/<key>/impl-plan.md` — task list from `/plan-impl` (halt if missing)
3. Read `_working/<key>/decisions.md` — resolved design decisions
4. Read `CLAUDE.md` — project conventions and test commands
5. Read `_loop-config.yaml` — test framework, coverage threshold

### Task Execution (per task, in dependency order)

For each task in the plan:

#### Phase 1: RED — Write Failing Test
- Write the test file/case FIRST
- Test must assert the expected behavior from the spec's AC
- Run tests — confirm the new test FAILS (for the right reason)
- If test passes immediately: the behavior already exists — mark task complete, skip to next

#### Phase 2: GREEN — Minimal Implementation
- Write the simplest code that makes the test pass
- Focus ONLY on making this specific test pass
- Do not optimize, do not add unrequested features
- Run tests — ALL tests must pass (new + existing)

#### Phase 3: REFACTOR — Clean Up
- Improve code structure, naming, duplication
- Apply patterns from `CLAUDE.md` and project conventions
- Run tests — confirm nothing broke

#### Phase 4: COMMIT
- Stage changed files
- Commit with message: `feat(<scope>): <what was implemented>`
- Conventional commit format

#### Phase 5: VERIFY
- Run full test suite (not just the new test)
- If regressions detected: fix immediately, commit fix
- Update task status in `_working/<key>/impl-plan.md`: mark `[x]`

### Failure Handling
- **Test failure after GREEN**: Debug using hypothesis-driven approach (≤3 attempts), then halt
- **Mock violation**: HALT immediately — this is NOT retryable
- **Regression in existing tests**: Fix and commit before continuing
- **3 consecutive task failures**: HALT the entire execution

### Completion
- All tasks marked `[x]` in impl-plan.md
- Full test suite passes
- Summary written to `_working/<key>/execution-summary.md`:
  - Tasks completed / total
  - Files created / modified
  - Test coverage delta (if measurable)
  - Any risks or notes for reviewer

## Reads
- `_working/<key>/spec.md`
- `_working/<key>/impl-plan.md`
- `_working/<key>/decisions.md`
- `CLAUDE.md`, `AGENTS.md`
- `_loop-config.yaml`

## Writes
- Source code files (implementation)
- Test files
- `_working/<key>/impl-plan.md` (task checkboxes)
- `_working/<key>/execution-summary.md`
- Git commits (one per task minimum)

## Retry Policy
3 retries per task. `mock_violation` is NOT retryable — halt immediately.

## Key Constraints
- Tests MUST be written BEFORE implementation (strict TDD)
- Each task = one RED/GREEN/Refactor cycle
- Never implement beyond what the current task requires
- All existing tests must continue to pass
- Commit after each successful task (atomic, reviewable commits)
