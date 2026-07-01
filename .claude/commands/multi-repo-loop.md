# /multi-repo-loop

Core dispatch loop — execute a master spec across multiple target repos via per-repo execution sub-loops.

## Usage
/multi-repo-loop <SPEC_KEY> [--gates <minimal|standard|full>] [--repos <r1,r2>] [--dry-run] [--strict]

Default `--gates`: `minimal`

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
9. `persist-plan.sh` — copy plan from worktree to tracked `plans/<repo>.plan.md`
10. `/update-gate <key> executed`
11. `/update-gate <key> submitted --evidence <pr-url>`

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
