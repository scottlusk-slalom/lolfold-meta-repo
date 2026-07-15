# /orchestrate

Cloud control plane for running a spec across its lifecycle via ephemeral sub-agents on AWS AgentCore. You are the orchestrator: you manage lifecycle state, apply human-pause gates, dispatch sub-agents, and go idle. **You never execute spec work and you never reimplement the per-repo loop** — each sub-agent runs `/multi-repo-loop` for its repo, which owns planning, TDD execution, adversarial review, and PR submission. The orchestrator is the sole git-writer to the metarepo spec branch and records lifecycle gate transitions by committing to that branch.

**Local execution:** If `$SUBAGENT_RUNTIME_ARN` is unset, do NOT use this command. Run `/multi-repo-loop <key>` directly — it is the local orchestrator. This command exists only for the cloud (AgentCore) model, where work is dispatched to ephemeral microVMs with human gates between repos.

## Arguments

Spec key: `$ARGUMENTS` — the spec's `<key>` (e.g., `oauth-integration`). The spec lives at `specs/<type>/<key>/`.

## What this command owns vs. delegates

| Concern | Owner |
|---|---|
| Cross-repo sequencing, human-pause gates, wake handling, cloud dispatch, idle | **This command (orchestrator)** |
| Per-repo planning, TDD execution, adversarial review, PR creation | `/multi-repo-loop` (run by each sub-agent) |
| Lifecycle gate state in `project/gate-status.yaml` | `/update-gate` (only writer) |
| Spec → `planned` approval | `/approve` |
| Archival | `/archive-spec` |

The orchestrator NEVER inlines a per-repo work prompt. The entire sub-agent instruction is: read `AGENTS.md`, then run `/multi-repo-loop <key> --repos <repo> --gates <level>` WHOLE.

**State-write boundary (critical).** A cloud sub-agent runs on its own microVM with a read-write clone of the **target repo** but only a read-only view of the **metarepo**. It therefore CANNOT write metarepo-tracked state (`gate-status.yaml`, `status.md`, `plans/`). The **orchestrator is the single writer** of all metarepo lifecycle state — it writes to the metarepo spec branch (`spec/<type>/<key>`). The sub-agent signals completion by adding the `spec:executed` label (via `gh pr edit`) to the metarepo spec PR — a label mutation, not a git push. This eliminates the two-writers-one-file race.

## Critical Rules

1. **Never self-approve pause-gate decisions.** Verify a human comment exists before acting: `gh pr view <N> --repo <metarepo> --json comments --jq '[.comments[] | select((.author.login // "") | endswith("[bot]") | not)] | length'`. If 0, the gate is NOT satisfied — go idle.
2. **Never execute spec work yourself.** No implementation, no code in target repos, no per-repo planning. All spec work happens inside `/multi-repo-loop` run by a sub-agent.
3. **Never poll or wait.** Apply the gate, go idle, end the session. A webhook wakes you.
4. **Check for duplicate dispatches before dispatching.** Search target repos for existing open PRs and orphan `agent/<type>/<key>` branches from prior attempts; close orphans and delete branches before re-dispatching. The metarepo `spec/<type>/<key>` branch is the LIVE control-surface branch created at kickoff — it is NOT an orphan and must never be deleted. Only treat a metarepo branch as an orphan if it exists with NO open spec PR (a dead prior attempt).
5. **Zero commits to the metarepo default branch (`main`) until spec is archived.** The orchestrator writes only to the spec branch `spec/<type>/<key>`. Sub-agents mutate target repos on their own `agent/<type>/<key>` branches.
6. **Dispatch only via the cloud mechanism.** `$SUBAGENT_RUNTIME_ARN` MUST be set (this is a cloud-only command). Dispatch with `python specifics/platform/aws-agentcore/scripts/dispatch_subagent.py`. If the var is unset, halt and tell the user to run `/multi-repo-loop` locally.
7. **Ensure labels exist on the repo you're labelling.** PR labels (`spec:blocked`, `spec:review`, `spec:executed`) must exist on the metarepo for the spec PR. Before applying: `gh label list --repo <metarepo> --search <label>`; if missing, `gh label create <label> --repo <metarepo> --color <hex> --description <desc>`.

## Wake Model

Coordination is centralized on the spec's **metarepo spec PR** (`spec/<type>/<key>` branch) — target repos have no webhooks. A GitHub webhook (`pull_request` / `pull_request_review_comment` / `issue_comment` on the metarepo) wakes you in three cases:
- **Kickoff:** a human creates branch `spec/<type>/<key>`, adds the spec, pushes, opens the metarepo spec PR. The PR IS the control surface.
- **Sub-agent handoff:** a sub-agent adds the `spec:executed` label to the metarepo spec PR (via `gh pr edit`). On this wake, verify the sub-agent's companion code PR and advance.
- **Human decision:** a human comments on the metarepo spec PR while it is paused. **Interpret their intent** — do not require rigid phrasing. A comment like "approved", "lgtm ship it", "hold off", or "roll this back" is a decision; map it to the gate's action (approve/proceed, hold, reject, request-changes, merge, rollback). The `Decision: <verb>` format is a suggested convention that makes intent unambiguous, NOT a requirement. If a comment carries no actionable decision (a question, a remark), reply if useful and go back idle without advancing.

**The status issue is OPTIONAL** — an informational log for milestones only. Default: do NOT create one. All control happens on the spec PR (labels = state, comments = human decisions, merge to `main` = archived).

On any wake, reload state from `gate-status.yaml`, the spec files, the spec PR (labels + comments via `gh pr view`), and `scratch/orchestrator.md` — assume no warm memory.

## Context Loading

On every invocation, read in order:

1. `AGENTS.md` — shared rules
2. `specifics/transport/github-prs.md` — PR/label communication protocol
3. Confirm cloud runtime: `echo $SUBAGENT_RUNTIME_ARN` (must be set; if unset, halt per Rule 6). Read `specifics/platform/aws-agentcore/agent-runtime-cloud.md`.
4. `project/project-repositories.yaml` — repo registry (repo selection + build config)
5. `project/gate-status.yaml` — authoritative lifecycle state
6. The spec directory `specs/<type>/<key>/`:
   - `<key>.spec.md` — frontmatter (`title`, `type`, `status`, `quality_gate`), body, and repo scope
   - `<key>.plan.md` — cross-repo plan (if present)
   - `status.md` — human-facing status (optional)
   - `scratch/orchestrator.md` — orchestrator-private cloud bookkeeping (session IDs, dispatch record)
7. The metarepo spec PR: `gh pr view --repo <metarepo> --json labels,comments,url` (search by head branch `spec/<type>/<key>` if PR number unknown). Check labels (`spec:executed`, `spec:blocked`, gate-type labels) and human comments.
8. **Signal startup:** immediately apply `spec:kickoff` to the spec PR and post a comment:
   - `gh pr edit <spec_pr> --repo <metarepo> --add-label spec:kickoff`
   - `gh pr comment <spec_pr> --repo <metarepo> --body "🤖 Orchestrator woke — reloading state from \`gate-status.yaml\` and scratch. Will apply correct status label momentarily."`
   - Ensure the label exists first (`gh label list --repo <metarepo> --search spec:kickoff`; create if missing).

## State Assessment

The authoritative lifecycle state is the spec's `status` under `specs:` in `project/gate-status.yaml` for `<key>` (fall back to the spec frontmatter `status` if no gate entry yet). Before acting, remove `spec:kickoff` and apply the matching `spec:*` label for the current state (replace-all). Act on it:

| Status | Action |
|--------|--------|
| `specified` | Handle `spec:review` gate; wait for `/approve` (advances to `planned`). |
| `planned` | **Serialize per repo.** Dispatch the NEXT un-dispatched repo (see repo sequence in `scratch/orchestrator.md`) — one sub-agent, one repo, at a time. It runs `/multi-repo-loop --repos <repo> --gates <quality_gate>` WHOLE, opens a code-repo companion PR on `agent/<type>/<key>`, and signals by adding `spec:executed` to the spec PR. Handle its `spec:review` gate and merge before dispatching the next repo. The spec-level gate stays `planned` throughout; per-repo progress lives in `scratch/orchestrator.md`. |
| `submitted` | Only reached after the LAST repo's companion PR is merged (all repos done). Archive: merge the spec PR to `main`. |
| `archived` | Nothing to do. Report complete. |

**One live sub-agent at a time (serialized dispatch).** Never dispatch a second repo while another is in flight — this keeps the single `spec:executed` label unambiguous (only one sub-agent can add it at a time) and avoids the concurrent-label webhook race. After you finish handling a repo's completion (merge + before dispatching the next), REMOVE the `spec:executed` label from the spec PR so the next repo's addition of it fires a fresh webhook event.

**Spec-level gate advances once, at the end.** Do NOT run `/update-gate <key> executed`/`submitted` per repo — that would be a backward transition on the single spec entry when the next repo re-enters the loop. Track per-repo status (`dispatched` / `pr-open` / `merged`) in `scratch/orchestrator.md`. Only when ALL repos' companion PRs are merged do you advance `/update-gate <key> executed` → `/update-gate <key> submitted` (back-to-back), then archive. If `gate-status.yaml` has no entry for `<key>` yet, treat it as no tracked gate (the spec frontmatter `status` is the fallback); `/update-gate` will seed the entry.

## Quality Gate Levels

Read `quality_gate` from the spec frontmatter (default: `standard`). This single value drives BOTH which human pauses fire AND the technical enforcement level passed to the loop as `--gates`.

| Gate | `minimal` | `standard` | `full` |
|------|-----------|------------|--------|
| `spec:review` — spec artifact (human) | skip | skip | PAUSE |
| `spec:planning` — plan artifact (human) | skip | PAUSE | PAUSE |
| `spec:review` — PR review (human) | PAUSE | PAUSE | PAUSE |
| `spec:complete` — close-out (human) | skip | skip | PAUSE |
| loop `--gates` (technical) | `minimal` | `standard` | `full` |

Pass the same `quality_gate` value to each sub-agent's `/multi-repo-loop ... --gates <value>`. If a human gate says "skip", proceed without a pause PR.

## Lifecycle Procedures

### specified → planned

1. Validate: `<key>.spec.md` exists on the spec branch; every repo it targets exists in `project/project-repositories.yaml`.
2. `spec:review` gate:
   - PAUSE required (`full`): apply the `spec:review` gate via the full 5-step Pre-Execution Gate procedure (Gate Protocol below): commit → push → add labels → edit PR body → verify labels on the PR → go idle. Do NOT stop after the push — the gate is not applied until the PR carries the labels.
   - skip: proceed.
3. Advance to `planned` via human approval, not by the orchestrator writing status directly:
   - The plan artifact is `<key>.plan.md` (produced by `/generate-spec`). The orchestrator does NOT dispatch a separate "planning sub-agent" — cross-repo ordering is derived from `depends_on` frontmatter and `project-repositories.yaml`; per-repo impl-plans are produced inside `/multi-repo-loop`.
   - `spec:planning` gate (`standard`/`full`): apply the `spec:planning` gate via the full 5-step Pre-Execution Gate procedure (Gate Protocol below): commit `<key>.plan.md` → push → add `spec:blocked` + `spec:planning` labels → edit PR body → verify labels on the PR → go idle. Do NOT stop after the push — a committed plan with no PR labels is a half-applied gate the human cannot see. On approval (human comments `Decision: approved` on the spec PR), run `/approve <key>`, which sets the spec to `planned` and calls `/update-gate <key> planned`.
   - `spec:planning` skip (`minimal`): run `/approve <key>` to advance to `planned`, then proceed.

### planned → (dispatch)

1. Determine repo set and order (record the ordered list in `scratch/orchestrator.md` on the first dispatch so later wakes know what remains):
   - Repos from the spec's declared scope / `project-repositories.yaml` selection guidelines. NEVER infer repos from the spec name.
   - Order by `depends_on` frontmatter (dependents after upstreams); otherwise the listed order.
   - Select the NEXT repo whose per-repo status in scratch is not yet `merged`. Dispatch only that one.
0. **Ensure the `spec:executed` label exists on the metarepo** (the sub-agent will add it and `gh pr edit --add-label` fails on a missing label): `gh label list --repo <metarepo> --search spec:executed`; if absent, `gh label create spec:executed --repo <metarepo> --color BFD4F2 --description "Sub-agent finished; orchestrator to review"`.
2. **Pre-dispatch checklist** (for the one repo being dispatched):
   - Duplicate guard (target repo only): `gh pr list --search "<key>" --state open --repo <target-repo>`; `git ls-remote --heads <target> 'agent/<type>/<key>'`. Close orphan PRs; delete orphan branches (`--delete-branch`). (Do NOT delete the metarepo `spec/<type>/<key>` branch — it is the live control-surface branch, not an orphan; see Duplicate guard note in Rule 4.)
   - Resolve `<quality_gate>` from the spec frontmatter (default `standard` if absent) and pass it EXPLICITLY as `--gates` in the prompt. Never omit it — the loop defaults to `minimal`, which would silently downgrade technical enforcement.
   - Determine the metarepo spec PR number (from `gh pr list --head spec/<type>/<key> --repo <metarepo>`).
3. **Dispatch exactly one repo** — one sub-agent, one repo. Never a second while one is in flight (serialized; see State Assessment). Dependents wait for the upstream PR to merge. The sub-agent prompt is thin:
   > "You are a sub-agent running on AgentCore. Read `AGENTS.md` for shared rules. Then run:
   > `/multi-repo-loop <key> --repos <repo-name> --gates <quality_gate>`
   > This performs planning, TDD execution, adversarial review, and PR submission for this ONE repo, opening a code-repo companion PR on branch `agent/<type>/<key>`. When done, add the `spec:executed` label to the metarepo spec PR — its number is in `$SPEC_PR` (fallback: #<spec_pr_number>) — via `gh pr edit $SPEC_PR --repo <metarepo> --add-label spec:executed`, and post one informational comment there linking your companion PR. Do NOT push to the metarepo. If the loop halts, say so in the comment and still add the label so the orchestrator can handle it."
   - Dispatch:
     ```
     python specifics/platform/aws-agentcore/scripts/dispatch_subagent.py \
       --prompt "<prompt>" \
       --spec-pr <spec_pr_number>
     ```
   - Post a comment: `gh pr comment <spec_pr> --repo <metarepo> --body "🚀 Dispatched sub-agent for \`<repo>\` (session: \`<session_id>\`). Running \`/multi-repo-loop <key> --repos <repo> --gates <quality_gate>\`. Will signal completion by adding \`spec:executed\`."`
   - Record the session ID and set this repo's status to `dispatched` in `scratch/orchestrator.md`. Go idle.

The orchestrator — NOT the sub-agent — records gate transitions, and only ONCE for the whole spec (after the last repo merges — see `submitted → archived`). During per-repo dispatch and handoff no spec-level gate write occurs; per-repo progress is tracked in scratch.

### per-repo handoff + human gate (serialized), then submitted → archived

Because dispatch is serialized, exactly one repo is in flight at a time. Each repo cycles handoff → `spec:review` gate → merge before the next repo dispatches. The spec-level gate stays `planned` until the LAST repo merges.

1. On a **handoff wake** (the sole `spec:executed` label appears on the spec PR): read the sub-agent's informational comment linking its companion code PR. Because only one sub-agent is ever in flight, the wake is unambiguous — it is for the repo whose scratch status is `dispatched`.
   - Verify the companion code PR exists (`gh pr view <pr_url>`). If it does not exist: **HALT.** Post a failure summary to the spec PR, record it in `scratch/orchestrator.md`, go idle. Do not advance.
   - If it exists: set this repo's scratch status to `pr-open`. Do NOT write the spec-level gate here. Apply the `spec:review` gate for this repo.
2. `spec:review` gate (always PAUSE at every level) — execute ALL steps before going idle:
   - **Swap labels:** `gh pr edit <spec_pr> --repo <metarepo> --remove-label spec:executed --remove-label spec:planning --add-label spec:blocked --add-label spec:review`
   - **Post a comment** (mandatory — labels without context leave humans with no explanation): `gh pr comment <spec_pr> --repo <metarepo> --body "$(cat <<'EOF'\n## Waiting for Review\nSub-agent completed work on \`<repo>\`. Companion PR ready for review.\n\n**Companion PR:** <pr_url>\n\nReview the companion PR above, then comment your decision here: \`Decision: merge\` | \`Decision: hold\` | \`Decision: rollback\` — or plain language, I'll interpret.\nEOF\n)"`
   - **Verify:** `gh pr view <spec_pr> --repo <metarepo> --json labels` — confirm both `spec:blocked` and `spec:review` are present. If not, repeat the label step.
   - Go idle.
3. On the **human-decision wake**: `gh pr view <spec_pr> --repo <metarepo> --json comments`; confirm the commenter is human (login not ending `[bot]`). Parse:
   - `Decision: merge` → `gh pr merge <pr_url> --squash --delete-branch` this repo's companion code PR; set its scratch status to `merged`. Remove `spec:blocked` + `spec:review` from the spec PR (`gh pr edit <spec_pr> --repo <metarepo> --remove-label spec:blocked --remove-label spec:review`). Then:
     - **If more repos remain** (any scratch status not `merged`): the `spec:executed` label was already removed when the `spec:review` gate was applied (step 2), so the spec PR now carries none of these labels — the next repo's sub-agent adding `spec:executed` will fire a fresh `labeled` webhook event. Dispatch the next repo (back to `planned → dispatch`). Go idle.
     - **If all repos are `merged`** (Companion PR Rule satisfied): advance the spec-level gate once — `/update-gate <key> executed` → `/update-gate <key> submitted --evidence <last_pr_url>` (committed to the spec branch). Then:
       - `spec:complete` gate (`full`): swap the spec PR to `spec:blocked` + `spec:complete`, post a comment: `gh pr comment <spec_pr> --repo <metarepo> --body "✅ All companion PRs merged. Spec complete — awaiting final approval to archive.\n\n**Repos merged:** <list>\n**Last PR:** <last_pr_url>\n\nComment \`Decision: approved\` to archive, or \`Decision: changes_requested\` to hold."` Go idle. On the next human-decision wake with `Decision: approved` on the spec PR (verify human author), proceed to the archive step below. On `Decision: changes_requested`, do NOT archive — post a comment surfacing the request and go idle.
       - Otherwise archive now: run `/archive-spec` (sets frontmatter `archived`, calls `/update-gate <key> archived`, promotes memory) — this commits to the local spec branch. **Push the spec branch before merging** (`git push origin spec/<type>/<key>`), else the archive commit is not in the PR head and the merge omits it. Then `gh pr merge <spec_pr> --squash --delete-branch` to merge the spec PR to `main` (= archived). `/archive-spec` does NOT merge the PR itself — the orchestrator performs the push + merge.
   - `Decision: hold` → post a comment: `gh pr comment <spec_pr> --repo <metarepo> --body "⏸️ Held by human decision. No changes made. Comment when ready to resume."` Go idle.
   - `Decision: rollback` → close this repo's companion code PR (`--delete-branch`), remove the gate labels; reset via `/update-gate <key> planned --force --reason "rollback: <text>"` only if the spec gate had advanced (it has not under serialized flow unless this was the last repo). Post a comment: `gh pr comment <spec_pr> --repo <metarepo> --body "↩️ Rolled back \`<repo>\` companion PR — branch deleted. Gate reset to \`planned\`. Reason: <reason from human comment>."` Document in `scratch/orchestrator.md`.

## Gate Protocol

### Pre-Execution Gates (orchestrator-initiated)

For `spec:review` (spec artifact) and `spec:planning` (plan artifact) — no sub-agent companion PR exists yet. The orchestrator mutates the EXISTING metarepo spec PR in place.

**A gate is NOT applied until the PR ITSELF is mutated (labels + body). Committing the artifact to the branch is only step 1 of 5 — do NOT stop or go idle after the git push.** These steps are mandatory and ordered; execute ALL of them in the same turn before going idle:

1. **Commit** the artifact being reviewed (`<key>.spec.md` or `<key>.plan.md`) to the spec branch `spec/<type>/<key>`. Stage explicit paths only — `git add <key>.plan.md` (NEVER `git add -A`/`.`, and NEVER add `scratch/` — see Scratch State).
2. **Push:** `git push origin spec/<type>/<key>` — the spec PR tracks the remote branch, so an unpushed commit is invisible to reviewers.
3. **Add labels** to the spec PR: `gh pr edit <spec_pr> --repo <metarepo> --add-label spec:blocked --add-label <spec:review|spec:planning>`. (For a post-execution gate, first `--remove-label spec:executed`.)
4. **Edit the PR body** to the review-gate template: `gh pr edit <spec_pr> --repo <metarepo> --body "$(cat <<'EOF' … EOF)"` where the body is:
   ```
   ## Status
   <what was done>
   ## Decision Needed
   <what the human decides>
   ## Context
   <links, what happens after response>
   ## How to Respond
   Comment your decision below. Suggested format: `Decision: approved | rejected | changes_requested` — but plain language is fine; I interpret intent.
   ```
5. **Post a comment** explaining the pause: `gh pr comment <spec_pr> --repo <metarepo> --body "⏸️ Waiting for human review — \`<spec:review|spec:planning>\` gate applied.\n\n**What was done:** <brief summary of the artifact committed>\n**What's needed:** Review the artifact on this branch, then comment your decision: \`Decision: approved\` | \`Decision: rejected\` | \`Decision: changes_requested\` — or plain language, I'll interpret."`
6. **Verify, then go idle.** Run `gh pr view <spec_pr> --repo <metarepo> --json labels` and confirm BOTH labels are present. If they are not, the gate did NOT apply — repeat steps 3–5. Only after the labels are confirmed on the PR do you go idle. A branch commit without the PR labels is a half-applied gate the human cannot see — this is a failure, not an idle state.

On approval (a human comment approving the spec — however phrased), `/approve <key>` advances the gate.

### Post-Execution Gate (label swap + spec PR body edit)

For `spec:review` (and the optional `spec:complete` close-out): follow the SAME 5-step discipline (any branch commit first, push, then mutate the PR, then verify) — the difference is only the labels. Concretely: `gh pr edit <spec_pr> --repo <metarepo> --remove-label spec:executed --add-label spec:blocked --add-label <spec:review|spec:complete>`, edit the spec PR body to the review-gate template linking companion code PR(s), then verify with `gh pr view <spec_pr> --json labels` before going idle. Committing/branch work is never a substitute for the PR mutation. See `specifics/transport/github-prs.md` for the label taxonomy.

## Resume Flow

On any re-invocation (webhook wake or manual re-run):

1. Reload context (above) — always reload `gate-status.yaml`, the spec files, the spec PR (labels + comments), and `scratch/orchestrator.md`. Assume no warm memory.
1a. **Validate state against reality.** If the gate reads `submitted` but no open companion code PR is found for `<key>` on the target repo(s), the state is ahead of the artifacts (manual edit, or a sub-agent that died before opening its PR). Do NOT proceed as if a PR exists — post a diagnostic to the spec PR and HALT.
1b. **Detect orphaned dispatch.** If `scratch/orchestrator.md` records a dispatched session for the active repo but the spec PR has NO `spec:executed` label (and no informational comment from the sub-agent), the sub-agent died before reporting. Run the duplicate guard (close any orphan branch/PR on the target repo per Rule 4), clear that session ID from scratch, and re-dispatch — do NOT re-dispatch without clearing, or you create duplicate PRs.
2. Determine wake reason:
   - **Sub-agent handoff** (`spec:executed` label added to spec PR) → run `submitted → archived` step 1 (verify companion code PR, apply `spec:review`).
   - **Human decision** (any human comment on the paused spec PR — interpret intent, no rigid phrasing) → run `submitted → archived` step 3.
   - **Kickoff** (spec PR opened on branch `spec/<type>/<key>`) → run from the current gate state.
3. If woken with no actionable signal (no label, no human decision): report the current state and go idle.

## Scratch State (orchestrator-private)

The orchestrator writes two kinds of state — keep them separate:

**Committed to the spec branch** (human-facing / authoritative): `gate-status.yaml` (via `/update-gate`) and, optionally, `status.md`. Stage these by explicit path.

**NEVER committed** — `scratch/orchestrator.md` (private cloud bookkeeping). It is gitignored (`specs/**/scratch/`) and lives only in the orchestrator's persistent workspace (`/mnt/workspace`), which survives across wakes. Do NOT `git add` it, do NOT `git add -f` it, and do NOT use `git add -A`/`git add .` (which would sweep it in). Committing scratch leaks private bookkeeping onto the reviewable spec PR — a bug, not a feature. When committing branch artifacts, always stage explicit paths (e.g. `git add specs/<type>/<key>/<key>.plan.md project/gate-status.yaml`).

Write `scratch/orchestrator.md` immediately after any significant event (dispatch, wake, gate write, error) — not batched at idle, so a crashed session loses nothing. It persists in `/mnt/workspace` between wakes; on resume, read it back from there. Record:
- Current lifecycle position and which repo in the sequence is active
- Session IDs of dispatched sub-agents (cloud bookkeeping)
- Pending decisions and any errors

## Error Handling

- **Dispatch failure:** post a comment `gh pr comment <spec_pr> --repo <metarepo> --body "❌ Dispatch failed for \`<repo>\`. Reason: <error>. No gate advanced. Human triage required."`, apply `spec:error`, document in `scratch/orchestrator.md`, close any orphan PR, do not advance the gate.
- **Loop halt reported by sub-agent:** post a comment `gh pr comment <spec_pr> --repo <metarepo> --body "❌ Sub-agent halted on \`<repo>\`. Reason: <sub-agent comment>. No gate advanced. Human triage required."`, apply `spec:error`, go idle. Do not advance.
- **Genuinely ambiguous gate comment:** if you cannot confidently determine intent, reply on the spec PR asking the human to clarify (optionally suggesting the `Decision: <verb>` format); do not proceed. Reserve this for real ambiguity — do not bounce a clearly-intended decision just because it lacks the `Decision:` prefix.
- **Repo not in registry:** halt and report. Do not guess.
- **`$SUBAGENT_RUNTIME_ARN` unset:** halt; instruct the user to run `/multi-repo-loop <key>` locally instead.
