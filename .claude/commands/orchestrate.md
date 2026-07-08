# /orchestrate

Orchestrate a spec through its full lifecycle. You are the orchestrator — you manage state, dispatch sub-agents, and create gates. You never execute spec work yourself.

## Arguments

Spec path: `$ARGUMENTS` (e.g., `feature/oauth-integration` or `feature/platform-migration/phase-1`)

## Critical Rules

1. **Never self-approve pause-gate PRs.** Verify a human comment exists before acting: `gh pr view <N> --json comments --jq '[.comments[] | select((.author.login // "") | endswith("[bot]") | not)] | length'`. If 0, the gate is NOT satisfied — go idle.
2. **Never execute spec work yourself.** No implementation, no code changes in target repos. Dispatch sub-agents for all spec work.
3. **Never poll or wait.** Create the gate PR and go idle. In local mode, inform the user and stop. In cloud mode, end session.
4. **Check for duplicate dispatches before dispatching.** Search for existing open PRs, branches, and status issues from prior attempts. Close orphans before re-dispatching.
5. **Zero commits to main between dispatch and merge of sub-agent PR.** All gate mutations happen on the sub-agent's branch or orchestrator review branch.
6. **Dispatch via the correct mechanism.** If `$SUBAGENT_RUNTIME_ARN` is set, use `python specifics/platform/aws-agentcore/scripts/dispatch_subagent.py`. If unset, use the Agent tool (in-process).
7. **No duplicate status comments.** Before posting to a status issue, check existing comments: `gh issue view <N> --repo <repo> --json comments --jq '[.comments[].body]'`. If a comment with the same status keyword (e.g., "Sub-agent complete", "dispatched") already exists for the same repo, do NOT post another.
8. **Ensure labels exist before applying them.** Before swapping labels on a PR, verify the label exists: `gh label list --repo <repo> --search <label>`. If missing, create it: `gh label create <label> --repo <repo> --color <hex> --description <desc>`.

## Context Loading

On every invocation, read these files in order:

1. `AGENTS.md` — shared rules
2. `specifics/transport/github-prs.md` — PR communication protocol
3. Detect runtime: `echo $SUBAGENT_RUNTIME_ARN`
   - Set → read `specifics/platform/aws-agentcore/agent-runtime-cloud.md`
   - Unset → read `specifics/platform/aws-agentcore/agent-runtime-local.md`
4. `project/project-repositories.yaml` — repo registry
5. The spec directory: `specs/$ARGUMENTS/`
   - `spec.yaml` — metadata, status, repos, quality gate level
   - `SPEC.md` — technical specification
   - `scratch/plan.md` — execution plan (if exists)
   - `scratch/orchestrator.md` — prior orchestrator state (if exists)
6. Check for open gate PRs: `gh pr list --label orchestrator-pause --state open --search "$ARGUMENTS"`

## State Assessment

Read `spec.yaml` field `status`. Act based on current state:

| Status | Action |
|--------|--------|
| `specified` | Validate spec, handle spec-review gate, advance to `planned` |
| `planned` | Dispatch execution sub-agent(s), one per repo sequentially |
| `executed` | Review results, open PR(s) in target repos, advance to `submitted` |
| `submitted` | Check for human review decision on PR(s), merge or re-work |
| `archived` | Nothing to do. Report complete. |

## Quality Gate Levels

Read `quality_gate` from `spec.yaml` (default: `standard`). This determines which gates require human pause:

| Gate | `minimal` | `standard` | `full` |
|------|-----------|------------|--------|
| `spec-review` | skip | skip | PAUSE |
| `plan-review` | skip | PAUSE | PAUSE |
| `pr-review` | PAUSE | PAUSE | PAUSE |
| `spec-complete` | skip | skip | PAUSE |

If the gate level says "skip" for a given gate, proceed without creating a pause PR.

## Lifecycle Procedures

### specified → planned

1. Validate the spec: confirm `SPEC.md` exists, repos listed in `spec.yaml` exist in `project/project-repositories.yaml`.
2. Check quality gate level for `spec-review`:
   - If gate requires pause: create pre-execution gate PR (see Gate Protocol below). Go idle.
   - If gate skips: proceed to step 3.
3. If resuming after `spec-review` approval (or gate skipped):
   - Dispatch a planning sub-agent OR run `/plan-impl` locally if spec is single-repo and simple.
   - For multi-repo specs, dispatch a planning sub-agent with instruction:
     > "Read AGENTS.md. Read the spec at specs/$ARGUMENTS/SPEC.md. Produce an execution plan at specs/$ARGUMENTS/scratch/plan.md covering all repos. Include dependency order, per-repo task breakdown, and integration points."
4. Once plan exists, check quality gate for `plan-review`:
   - If gate requires pause: create pre-execution gate PR with the plan. Go idle.
   - If gate skips: update `spec.yaml` status to `planned`, commit, proceed.

### planned → executed

1. Read `scratch/plan.md` for repo execution order and dependency hints.
2. Read repos from `spec.yaml` field `repos` (list of repo names).
3. Determine execution order:
   - If plan specifies dependency order, follow it (e.g., API before frontend).
   - If no order specified, use the order listed in `spec.yaml`.
4. **Pre-dispatch checklist** (per repo):
   - Duplicate guard: `gh pr list --search "$ARGUMENTS" --state open` and `git ls-remote --heads origin agent/*/$ARGUMENTS/*`
   - Status issue exists: `gh issue list --label spec-status --state open --search "$ARGUMENTS"`. Create one if missing.
5. **Dispatch sequentially.** For each repo in order:
   - Compose sub-agent prompt:
     > "You are a sub-agent. Read AGENTS.md for shared rules. Execute the spec at specs/$ARGUMENTS/ for repo {repo-name}. Read the plan at specs/$ARGUMENTS/scratch/plan.md for your tasks. Work in the worktree at specs/$ARGUMENTS/repo/{repo-name}/. When done, open a PR on the target repo with label `sub-agent-complete` on branch `agent/{spec-type}/{spec-name}/{repo-name}`. Post ONE progress comment to status issue #{issue_number} — check existing comments first and do not duplicate."
   - **Cloud mode** (`$SUBAGENT_RUNTIME_ARN` set):
     ```
     python specifics/platform/aws-agentcore/scripts/dispatch_subagent.py \
       --prompt "<prompt>" \
       --status-issue <issue_number>
     ```
     Record session ID to `scratch/orchestrator.md`. Go idle.
   - **Local mode** (`$SUBAGENT_RUNTIME_ARN` unset):
     Use the Agent tool with `isolation: "worktree"` to dispatch the sub-agent in-process. Wait for completion before dispatching the next repo.
6. After all repos complete: update `spec.yaml` status to `executed`, commit and push to main.

### executed → submitted

1. Verify all sub-agent PRs exist (one per repo). Read PR bodies for companion PR links.
2. Check quality gate for `pr-review`:
   - If gate requires pause:
     a. Ensure labels exist on target repo (create if missing): `orchestrator-pause`, `pr-review`
     b. Mutate sub-agent PR(s) — swap `sub-agent-complete` label for `orchestrator-pause` + `pr-review`.
     c. Edit PR body with review-gate template. Go idle.
   - If gate skips: proceed to step 3.
3. Update `spec.yaml` status to `submitted`, commit and push.

### submitted → archived

1. Check for human decisions on open gate PRs:
   - `gh pr list --label orchestrator-pause --state open --search "$ARGUMENTS"`
   - For each: `gh pr view <N> --comments` — look for human comment.
2. Parse structured decision from comment:
   - `Decision: merge` → merge all companion PRs, then the metarepo PR. Delete branches.
   - `Decision: hold` → go idle, inform user.
   - `Decision: rollback` → close PRs, reset spec to `executed`, document in scratch.
3. After all PRs merged:
   - Check quality gate for `spec-complete`:
     - If gate requires pause: create close-out PR on branch `orchestrator/{spec-type}/{spec-name}/complete` with summary. Go idle.
     - If gate skips: proceed.
   - Update `spec.yaml` status to `archived`.
   - Close status issue.
   - Commit final state.

## Gate Protocol

### Pre-Execution Gates (orchestrator-initiated)

For `spec-review` and `plan-review` — no sub-agent PR exists yet:

1. Create branch: `orchestrator/{spec-type}/{spec-name}/review`
2. Commit the artifact being reviewed (spec or plan file).
3. Open PR with labels: `orchestrator-pause` + gate type (`spec-review` or `plan-review`).
4. PR body follows the review-gate template:
   ```
   ## Status
   <what was done>

   ## Decision Needed
   <what the human decides — numbered options if applicable>

   ## Context
   <links, metrics, what happens after response>

   ## How to Respond
   Leave a comment with: Decision: approved | rejected | changes_requested
   ```
5. Go idle.

### Post-Execution Gates (mutates sub-agent PR)

For `pr-review`, quality gates, and `spec-complete`:

1. Swap labels on sub-agent's PR: remove `sub-agent-complete`, add `orchestrator-pause` + specific gate label.
2. Edit PR body to review-gate template.
3. Go idle.

## Resume Flow

When re-invoked after going idle:

1. Load context (see Context Loading above).
2. Check for open gate PRs with human comments.
3. Verify commenter is human (not bot): check login does not end with `[bot]`.
4. Parse structured decision:
   - `Decision: approved` → merge/close gate PR (`--delete-branch`), proceed to next lifecycle step.
   - `Decision: rejected` → close gate PR, reset status one step back, document in scratch.
   - `Decision: changes_requested` → document feedback in scratch, inform user of needed changes, go idle.
5. If no human comment found on any open gate: report "Waiting for human decision on PR #N" and go idle.

## Scratch State

Before going idle, write orchestrator state to `specs/$ARGUMENTS/scratch/orchestrator.md`:
- Current lifecycle position
- Which repos have been dispatched / completed
- Session IDs (cloud mode)
- Pending decisions
- Errors encountered

On resume, read this file first for warm context recovery.

## Error Handling

- **Sub-agent dispatch failure:** Document in scratch, close any orphan PR, reset spec to prior state.
- **Ambiguous gate comment:** Reply with structured error requesting clarification. Do not proceed.
- **Missing plan file when status is `planned`:** Reset to `specified` and re-plan.
- **Repo not found in registry:** Halt and report. Do not guess.
