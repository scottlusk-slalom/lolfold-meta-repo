# /multi-repo-loop

Core dispatch loop — execute a master spec across multiple target repos via per-repo execution sub-loops.

**Cloud Mode:** If `$SUBAGENT_RUNTIME_ARN` is set AND `--report-only` is NOT passed, you are a top-level agent in the cloud — use `/orchestrate` instead. If `--report-only` IS passed, you were dispatched by the orchestrator as a sub-agent: proceed with this command (do NOT defer to `/orchestrate` — that would recurse). Without cloud env vars, this is the local orchestrator.

## Usage
/multi-repo-loop <SPEC_KEY> [--gates <minimal|standard|full>] [--repos <r1,r2>] [--dry-run] [--strict] [--report-only]

Default `--gates`: `minimal`

## Report-Only Mode (`--report-only`)

Used when a cloud sub-agent runs this loop for a single repo under `/orchestrate`. The sub-agent has a read-write clone of the **target repo** but only a read-only view of the **metarepo** (it runs on its own microVM). In this mode:

- Do the code work in the target repo worktree as normal: setup-worktree → stage-context → check-deps → `/plan-impl` → `/execute-impl` → check-mock-violations → `/review-impl` → `/submit-pr`.
- **SKIP all metarepo-tracked writes:** do NOT call `/update-gate`, do NOT run `persist-plan.sh`, do NOT write `status.md`. The orchestrator owns metarepo state and writes it on its own clone after parsing your report.
- Emit a structured completion report (see below) instead. `--report-only` requires exactly one repo via `--repos` — if zero or more than one repo is in scope, HALT with `report-only requires exactly one repo` (one LOOP-REPORT maps to one PR; multiple repos would orphan all but the last report).

### Completion Report (report-only)
```
LOOP-REPORT repo=<repo> spec=<key>
result: complete | halted
pr_url: <url or ->
review_verdict: PASS | PASS_WITH_NOTES | FAIL | -
gates_passed: <build,test,typecheck,...>
halt_reason: <text if halted, else ->
```
The orchestrator reads this from the sub-agent's status-issue comment and performs the `/update-gate <key> executed` → `/update-gate <key> submitted --evidence <pr_url>` transitions itself.

## Repo Selection
- Select repos from `when_to_use` and `selection_guidelines` in `project/project-repositories.yaml`
- NEVER infer repos from the spec name
- Override with `--repos` flag

## Per-Repo Execution Sequence

For each selected repo:

1. `setup-worktree.sh <repo> <type> <key> <branch>` — git worktree at `specs/<type>/<key>/repo/<repo>/` on `feat/<key>`
2. `stage-context.sh <type> <key> <repo>` — copy spec + analysis + decisions into `_working/<key>/`
3. `check-deps.sh` — verify required local services reachable (gate)
4. `/plan-impl` — generate implementation plan (retries: 0)
5. `/execute-impl` — TDD implementation (retries: 3; `mock_violation` NOT retryable)
6. `check-mock-violations.sh` — no new test mocks of constrained services (gate)
7. `/review-impl` — adversarial review (FAIL → retry execute, PASS → continue)
8. `/submit-pr` — push branch + open PR (retries: 1)

Steps 9-11 write **metarepo-tracked state** and run ONLY in local mode. In `--report-only` mode STOP after step 8 and emit the `LOOP-REPORT` instead (the orchestrator performs these on its own clone):

9. `persist-plan.sh` — copy plan from worktree to tracked `plans/<repo>.plan.md` *(local only)*
10. `/update-gate <key> executed` *(local only)*
11. `/update-gate <key> submitted --evidence <pr-url>` *(local only)*

## Gate Levels
- `minimal`: Stop only on test failures (3 retries). Skip dependency/SAST scans.
- `standard`: + dependency-scan critical/high. SAST advisory. E2E failures block.
- `full`: Stop on any test failure, any dependency-scan finding, SAST gate failure, or coverage < 80%.

## Flags
- `--gates`: Gate enforcement level (NOT `strict` — that's separate)
- `--strict`: Boolean — halt the ENTIRE run if any repo fails pre-flight
- `--dry-run`: Show what would execute without running

## Cross-Repo Dependencies
- Specs declare `depends_on: [repo-name]` in frontmatter
- Dependent repos run sequentially after upstream PR merges
- Independent repos may dispatch concurrently
- This is sequential proof per repo, NOT simultaneous deployment

## Retry Policy
| Command | Retries | Notes |
|---------|---------|-------|
| `/plan-impl` | 0 | Fail immediately |
| `/execute-impl` | 3 | `mock_violation` is NOT retryable |
| `/review-impl` | — | FAIL loops back to `/execute-impl` |
| `/submit-pr` | 1 | — |

## Gate Calls
- `/update-gate <key> executed` — after successful execution
- `/update-gate <key> submitted --evidence <pr-url>` — after PR created
- Add `--force` if gate entry is missing or behind `planned`
- **`--report-only` mode skips these entirely** — the orchestrator performs them on the metarepo clone after reading the loop report.

## Tracking
- Commit: `chore(<key>): loop results — {summary}`

## Reference Docs (injected at runtime)
- `.claude/commands/references/multi-repo-loop/gate-levels.md`
- `.claude/commands/references/multi-repo-loop/worktree-layout.md`
- `.claude/commands/references/multi-repo-loop/cross-repo-contracts.md`

## Reads
- `specs/*/<key>/<key>.spec.md`
- `specs/*/<key>/context/`
- `project/project-repositories.yaml`
- `repos/<repo>/_loop-config.yaml`
- `repos/<repo>/CLAUDE.md`
- `playbooks/<name>.md`

## Writes
Target-repo worktree (always, both modes): source, tests, commits, the PR.

Metarepo-tracked (local mode ONLY — skipped under `--report-only`, orchestrator writes these instead):
- `specs/<type>/<key>/sub-specs/<repo-name>.spec.md`
- `specs/<type>/<key>/status.md`
- `specs/<type>/<key>/plans/<repo-name>.plan.md`
- `_working/<SPEC_KEY>/constraints.md`
- `project/gate-status.yaml` (via `/update-gate`)

## Delegates To
- Scripts: `setup-worktree.sh`, `stage-context.sh`, `check-deps.sh`, `check-mock-violations.sh`, `persist-plan.sh`
- Commands: `/plan-impl`, `/execute-impl`, `/review-impl`, `/submit-pr`, `/update-gate`

## Important
- `integration_branch` from spec frontmatter = worktree base + PR target
- Feature work happens in spec worktrees, NEVER in `repos/<name>/` (that stays on default branch)
