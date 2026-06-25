# /multi-repo-aos-loop

Core dispatch loop — execute a master spec across multiple target repos via per-repo AOS sub-loops.

## Usage
/multi-repo-aos-loop <SPEC_KEY> [--gates <minimal|standard|full>] [--repos <r1,r2>] [--dry-run] [--strict]

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
4. `/aos-plan` — generate plan (retries: 0)
5. `/aos-execute` — TDD implementation (retries: 3; `mock_violation` NOT retryable)
6. `check-mock-violations.sh` — no new test mocks of constrained services (gate)
7. `/aos-submit-pr` — open PR (retries: 1)
8. `/pr-review` — review the PR
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
| `/aos-plan` | 0 | Fail immediately |
| `/aos-execute` | 3 | `mock_violation` is NOT retryable |
| `/aos-submit-pr` | 1 | — |

## Gate Calls
- `/update-gate <key> executed` — after successful execution
- `/update-gate <key> submitted --evidence <pr-url>` — after PR created
- Add `--force` if gate entry is missing or behind `planned`

## Tracking
- Commit: `chore(<key>): AOS loop results — {summary}`

## Reference Docs (injected at runtime)
- `.claude/commands/references/multi-repo-aos-loop/gate-levels.md`
- `.claude/commands/references/multi-repo-aos-loop/worktree-layout.md`
- `.claude/commands/references/multi-repo-aos-loop/cross-repo-contracts.md`

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
- Commands: `/aos-plan`, `/aos-execute`, `/aos-submit-pr`, `/pr-review`, `/update-gate`
- Do NOT chain `/aos-analyze` or `/aos-loop`

## Important
- `integration_branch` from spec frontmatter = worktree base + PR target
- Feature work happens in spec worktrees, NEVER in `repos/<name>/` (that stays on default branch)
