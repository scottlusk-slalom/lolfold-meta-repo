# /multi-repo-loop

Core dispatch loop — execute a master spec across multiple target repos via per-repo execution sub-loops.

**Cloud dispatch:** The distinguishing signal is `$DISPATCHED_BY_ORCHESTRATOR`, which the dispatch script sets on EVERY sub-agent it launches (the entrypoint exports the payload's `dispatched_by_orchestrator` to this env var). It is set only in dispatched sub-agents, never in a top-level session.
- If `$SUBAGENT_RUNTIME_ARN` is set AND `$DISPATCHED_BY_ORCHESTRATOR` is UNSET, you are a top-level cloud session — hand off to `/orchestrate`, do not run the loop yourself.
- If `$DISPATCHED_BY_ORCHESTRATOR` is set, you were dispatched BY the orchestrator as a sub-agent (your prompt names a single `--repos <repo>` and a spec PR to signal) — run the loop for that repo and do NOT defer to `/orchestrate` (that would recurse).
- Without `$SUBAGENT_RUNTIME_ARN`, this is the local orchestrator — run the loop directly.

Do NOT key this decision off the `--repos` arg shape alone: a human may legitimately run a single-repo `/multi-repo-loop <key> --repos <repo>` at top level in the cloud, which must still hand off to `/orchestrate`. The env marker is the authoritative signal.

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

Steps 9-11 write **metarepo-tracked state**:

**Local mode** (no `$SUBAGENT_RUNTIME_ARN`): the loop runs these steps itself:

9. `persist-plan.sh` — copy plan from worktree to tracked `plans/<repo>.plan.md`
10. `/update-gate <key> executed`
11. `/update-gate <key> submitted --evidence <pr-url>`

**Cloud dispatched-sub-agent mode** (`$DISPATCHED_BY_ORCHESTRATOR` set): STOP after step 8. The sub-agent adds the `spec:executed` label to the metarepo spec PR (`gh pr edit $SPEC_PR --repo <metarepo> --add-label spec:executed`) and posts one informational comment there linking its companion PR. It does NOT run persist-plan/update-gate — the orchestrator writes gate state on the spec branch. It does NOT push to the metarepo.

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
- Independent repos may run concurrently in LOCAL mode (the loop handles all repos itself)
- In CLOUD mode the orchestrator serializes dispatch — one sub-agent (one repo) in flight at a time, with a human `spec:review` gate between repos (see `/orchestrate`). A dispatched sub-agent only ever runs ONE repo.
- This is sequential proof per repo, NOT simultaneous deployment

## Retry Policy
| Command | Retries | Notes |
|---------|---------|-------|
| `/plan-impl` | 0 | Fail immediately |
| `/execute-impl` | 3 | `mock_violation` is NOT retryable |
| `/review-impl` | — | FAIL loops back to `/execute-impl` |
| `/submit-pr` | 1 | — |

## Gate Calls
**Local mode:** the loop calls `/update-gate` itself:
- `/update-gate <key> executed` — after successful execution
- `/update-gate <key> submitted --evidence <pr-url>` — after PR created
- Add `--force` if gate entry is missing or behind `planned`

**Cloud dispatched-sub-agent mode:** the sub-agent does NOT call `/update-gate`. The orchestrator writes gate state on the spec branch after the sub-agent signals completion via the `spec:executed` label.

## Spec PR Label Updates
When `$SPEC_PR` is set, apply these labels at key moments (replace-all pattern — remove existing gate labels before adding). Use `$LABEL_PREFIX` (default: `spec`):

| Moment | Label |
|---|---|
| Loop starts (before first repo) | `$LABEL_PREFIX:executed` |
| Awaiting human decision (`spec:blocked` applied) | `$LABEL_PREFIX:blocked` |
| Unrecoverable halt (exhausted retries, unexpected error) | `$LABEL_PREFIX:error` |

`/update-gate` writes only `gate-status.yaml` — it does NOT touch PR labels. The lifecycle-status label matching the current gate state (`spec:specified` / `spec:planned` / `spec:submitted`; `executed` has none, `archived` merges the PR) is applied by the **orchestrator** at the start of each wake (see `/orchestrate` → State Assessment), not by this loop and not by `/update-gate`. The moments in the table above are the ONLY labels this loop sets directly.

Skip silently if `$SPEC_PR` is unset. Never block loop execution if a label update fails.

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
**Target-repo worktree** (always, all modes): source, tests, commits, the PR.

**Metarepo-tracked** (local mode ONLY — in cloud dispatched-sub-agent mode, the orchestrator writes these on the spec branch instead):
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
