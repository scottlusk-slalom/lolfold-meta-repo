# /orchestrate

Cloud control plane for running a spec across its lifecycle via ephemeral sub-agents on AWS AgentCore. You are the orchestrator: you manage lifecycle state, apply human-pause gates, dispatch sub-agents, and go idle. **You never execute spec work and you never reimplement the per-repo loop** — each sub-agent runs `/multi-repo-loop` for its repo, which owns planning, TDD execution, adversarial review, and PR submission. The orchestrator records the lifecycle gate transitions itself (the cloud sub-agent cannot write metarepo state — see State-write boundary below).

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

The orchestrator NEVER inlines a per-repo work prompt. The entire sub-agent instruction is: read `AGENTS.md`, then run `/multi-repo-loop <key> --repos <repo> --gates <level> --report-only`.

**State-write boundary (critical).** A cloud sub-agent runs on its own microVM with a read-write clone of the **target repo** but only a read-only view of the **metarepo**. It therefore CANNOT write metarepo-tracked state (`gate-status.yaml`, `status.md`, `plans/`). That is why sub-agents run the loop in `--report-only` mode: they do the code work and open the target-repo PR, then report status back in a status-issue comment. The **orchestrator is the single writer** of all metarepo lifecycle state — it performs every `/update-gate` transition itself, on its own clone, after reading the sub-agent's report. This eliminates the two-writers-one-file race.

## Critical Rules

1. **Never self-approve pause-gate decisions.** Verify a human comment exists before acting: `gh issue view <N> --repo <metarepo> --json comments --jq '[.comments[] | select((.author.login // "") | endswith("[bot]") | not)] | length'`. If 0, the gate is NOT satisfied — go idle.
2. **Never execute spec work yourself.** No implementation, no code in target repos, no per-repo planning. All spec work happens inside `/multi-repo-loop` run by a sub-agent.
3. **Never poll or wait.** Apply the gate, go idle, end the session. A webhook wakes you.
4. **Check for duplicate dispatches before dispatching.** Search for existing open PRs, branches, and status comments from prior attempts. Close orphans before re-dispatching.
5. **Zero commits to the metarepo default branch between dispatch and PR merge** beyond gate-state updates via `/update-gate`. Sub-agents mutate target repos on their own branches.
6. **Dispatch only via the cloud mechanism.** `$SUBAGENT_RUNTIME_ARN` MUST be set (this is a cloud-only command). Dispatch with `python specifics/platform/aws-agentcore/scripts/dispatch_subagent.py`. If the var is unset, halt and tell the user to run `/multi-repo-loop` locally.
7. **No duplicate status comments.** Before posting to the status issue, check existing comments: `gh issue view <N> --repo <metarepo> --json comments --jq '[.comments[].body]'`. If a comment with the same status keyword already exists for the same repo, do NOT post another.
8. **Ensure labels exist on the repo you're labelling.** PR labels (`orchestrator-pause`, `pr-review`, `sub-agent-complete`) live on the **target repo** where the PR is; status labels (`spec-status`) live on the **metarepo**. Before applying: `gh label list --repo <that-repo> --search <label>`; if missing, `gh label create <label> --repo <that-repo> --color <hex> --description <desc>`. A label existing on the metarepo does NOT mean it exists on the target repo.
9. **Never emit the wake marker.** The string `<!-- ORCHESTRATOR-WAKE ... -->` is reserved for sub-agents signalling completion. If YOU write it, you re-wake yourself in an infinite loop. Only sub-agents emit it.

## Wake Model

Coordination is centralized on the spec's **metarepo status issue** — target repos have no webhooks. A GitHub webhook (`issues` / `issue_comment` on the metarepo) wakes you in three cases:
- **Kickoff:** a human opens an issue (or comments) with `/orchestrate <key>`. Launches the spec.
- **Sub-agent handoff:** a sub-agent posts a completion comment ending with `<!-- ORCHESTRATOR-WAKE spec=... -->`. On this wake, verify the sub-agent's PR and advance.
- **Human decision:** a human comments `Decision: merge|hold|rollback` on the status issue.

**Kickoff issue = status issue (reuse, never orphan).** When kickoff comes from an issue, that issue BECOMES the status issue:
1. Identify the kickoff issue number (referenced by the prompt/wake).
2. **Guard against duplicates first:** `gh issue list --label spec-status --state open --search "Status: <key>"`. If an adopted status issue already exists for this key and it is NOT the kickoff issue, close the kickoff with a pointer to it and use the existing one. Do not adopt a second.
3. Adopt it: `gh issue edit <n> --add-label spec-status --title "Status: <key>"`. Post the initial status as a comment.
4. Use this same issue for all status updates and the decision gate.
5. Only if NO kickoff issue exists (e.g. some non-issue trigger) do you create a fresh status issue, then close the kickoff with a pointer.

On any wake, reload state from `gate-status.yaml`, the spec files, the status issue, and `scratch/orchestrator.md` — assume no warm memory.

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
   - `status.md` — human-facing status
   - `scratch/orchestrator.md` — orchestrator-private cloud bookkeeping (session IDs, dispatch record)
7. Open gate PRs / status comments: `gh pr list --label orchestrator-pause --state open` and the status issue.

## State Assessment

The authoritative lifecycle state is `current_status` in `project/gate-status.yaml` for `<key>` (fall back to the spec frontmatter `status` if no gate entry yet). Act on it:

| Status | Action |
|--------|--------|
| `specified` | Handle `spec-review` gate; wait for `/approve` (advances to `planned`). |
| `planned` | Dispatch one sub-agent per repo (each runs `/multi-repo-loop --repos <repo> --report-only`). The sub-agent opens the target-repo PR and reports back; the orchestrator then records `executed` → `submitted` itself. |
| `submitted` | Apply `pr-review` pause on the open PR(s); await human `Decision:`; merge; archive. |
| `archived` | Nothing to do. Report complete. |

The gate never rests at `executed` under orchestrator control: on the handoff wake the orchestrator records `executed` then `submitted` back-to-back from the loop report, then pauses at `pr-review`. If `gate-status.yaml` has no entry for `<key>` yet, treat it as no tracked gate (the spec frontmatter `status` is the fallback); `/update-gate` will seed the entry.

## Quality Gate Levels

Read `quality_gate` from the spec frontmatter (default: `standard`). This single value drives BOTH which human pauses fire AND the technical enforcement level passed to the loop as `--gates`.

| Gate | `minimal` | `standard` | `full` |
|------|-----------|------------|--------|
| `spec-review` (human) | skip | skip | PAUSE |
| `plan-review` (human) | skip | PAUSE | PAUSE |
| `pr-review` (human) | PAUSE | PAUSE | PAUSE |
| `spec-complete` (human) | skip | skip | PAUSE |
| loop `--gates` (technical) | `minimal` | `standard` | `full` |

Pass the same `quality_gate` value to each sub-agent's `/multi-repo-loop ... --gates <value>`. If a human gate says "skip", proceed without a pause PR.

## Lifecycle Procedures

### specified → planned

1. Validate: `<key>.spec.md` exists; every repo it targets exists in `project/project-repositories.yaml`.
2. `spec-review` gate:
   - PAUSE required (`full`): create a pre-execution gate PR with the spec (see Gate Protocol). Go idle.
   - skip: proceed.
3. Advance to `planned` via human approval, not by the orchestrator writing status directly:
   - The plan artifact is `<key>.plan.md` (produced by `/generate-spec`). The orchestrator does NOT dispatch a separate "planning sub-agent" — cross-repo ordering is derived from `depends_on` frontmatter and `project-repositories.yaml`; per-repo impl-plans are produced inside `/multi-repo-loop`.
   - `plan-review` gate (`standard`/`full`): create a pre-execution gate PR with `<key>.plan.md`. Go idle. On approval, the human (or the merge) runs `/approve <key>`, which sets the spec to `planned` and calls `/update-gate <key> planned`.
   - `plan-review` skip (`minimal`): run `/approve <key>` to advance to `planned`, then proceed.

### planned → (dispatch)

1. Determine repo set and order:
   - Repos from the spec's declared scope / `project-repositories.yaml` selection guidelines. NEVER infer repos from the spec name.
   - Order by `depends_on` frontmatter (dependents after upstreams); otherwise the listed order.
2. **Pre-dispatch checklist** (per repo):
   - Duplicate guard: `gh pr list --search "<key>" --state open` on the target repo, and `git ls-remote --heads <target> 'feat/<key>'`.
   - Status issue exists (adopt kickoff issue if needed — see Wake Model).
   - Resolve `<quality_gate>` from the spec frontmatter (default `standard` if absent) and pass it EXPLICITLY as `--gates` in the prompt. Never omit it — the loop defaults to `minimal`, which would silently downgrade technical enforcement.
3. **Dispatch sequentially** — exactly one repo per sub-agent (never pass multiple repos to one sub-agent; the orchestrator owns cross-repo sequencing and the human gate between repos). Dependents wait for the upstream PR to merge. For each repo, the sub-agent prompt is thin:
   > "You are a sub-agent running on AgentCore. Read `AGENTS.md` for shared rules. Then run:
   > `/multi-repo-loop <key> --repos <repo-name> --gates <quality_gate> --report-only`
   > This performs planning, TDD execution, adversarial review, and PR submission for this ONE repo in the target-repo worktree. `--report-only` means: do NOT write metarepo state — the orchestrator does that. When done, post ONE completion comment to metarepo status issue #<issue_number> — check existing comments first, do not duplicate — containing the loop's `LOOP-REPORT` block and ending with the exact wake marker on its own line:
   > `<!-- ORCHESTRATOR-WAKE spec=<type>/<key> -->`
   > If the loop halts (test or review gate exhausted), the report's `result: halted` and `halt_reason` carry the failure — still end with the wake marker so the orchestrator can handle it."
   - Dispatch:
     ```
     python specifics/platform/aws-agentcore/scripts/dispatch_subagent.py \
       --prompt "<prompt>" \
       --status-issue <issue_number>
     ```
   - Record the session ID to `scratch/orchestrator.md`. Go idle.

The orchestrator — NOT the sub-agent — records gate transitions. It does so on the handoff wake (next section), after reading the `LOOP-REPORT`. During dispatch itself no gate write occurs.

### submitted → archived

Reached on a sub-agent handoff wake (loop complete, PR open, gate at `submitted`) followed by a human-decision wake.

1. On the **handoff wake**: read the `LOOP-REPORT` from the sub-agent's status-issue comment.
   - If `result: halted` (or the PR referenced by `pr_url` does not exist): **HALT.** Post a failure summary (include `halt_reason`) to the status issue, record it in `scratch/orchestrator.md`, go idle. Do not advance the gate.
   - If `result: complete` and `pr_url` resolves to an open PR: **record the gate transitions the sub-agent could not write** — `/update-gate <key> executed` then `/update-gate <key> submitted --evidence <pr_url>`. Then apply the `pr-review` gate.
2. `pr-review` gate (always PAUSE at every level):
   - Ensure `orchestrator-pause` + `pr-review` labels exist on the target repo; apply them to the sub-agent PR.
   - Post a review-gate comment to the **metarepo status issue** (not the target PR) linking each PR and stating how to respond. Do NOT emit the wake marker (Rule 9). Go idle.
     > "Review the PR(s) linked above, then comment here: `Decision: merge` | `Decision: hold` | `Decision: rollback`."
3. On the **human-decision wake**: `gh issue view <issue> --repo <metarepo> --comments`; confirm the commenter is human (login not ending `[bot]`). Parse:
   - `Decision: merge` → `gh pr merge --squash --delete-branch` each PR. Then, if more repos remain in the sequence, dispatch the next repo (back to `planned → dispatch`). If all repos are done:
     - `spec-complete` gate (`full`): post a close-out summary, go idle.
     - Run `/archive-spec` (sets frontmatter `archived`, calls `/update-gate <key> archived`, promotes memory). Close the status issue.
   - `Decision: hold` → go idle, inform the user.
   - `Decision: rollback` → close the PR(s), and reset via `/update-gate <key> planned --force --reason "rollback: <text>"`. Document in `scratch/orchestrator.md`.

## Gate Protocol

### Pre-Execution Gates (orchestrator-initiated)

For `spec-review` and `plan-review` — no sub-agent PR exists yet:

1. Branch: `orchestrator/<type>/<key>/review`.
2. Commit the artifact being reviewed (`<key>.spec.md` or `<key>.plan.md`).
3. Open a PR labelled `orchestrator-pause` + gate type (`spec-review` | `plan-review`).
4. PR body (review-gate template):
   ```
   ## Status
   <what was done>
   ## Decision Needed
   <what the human decides>
   ## Context
   <links, what happens after response>
   ## How to Respond
   Comment: Decision: approved | rejected | changes_requested
   ```
5. Go idle. On approval, `/approve <key>` advances the gate.

### Post-Execution Gate (label swap + status-issue comment)

For `pr-review` (and the optional `spec-complete` close-out): swap `sub-agent-complete` → `orchestrator-pause` + gate label on the PR, post the review-gate comment to the **status issue** (not the PR), do NOT emit the wake marker, go idle. See `specifics/transport/github-prs.md` for the label taxonomy.

## Resume Flow

On any re-invocation (webhook wake or manual re-run):

1. Reload context (above) — always reload `gate-status.yaml`, the spec files, the status issue, and `scratch/orchestrator.md`. Assume no warm memory.
1a. **Validate state against reality.** If the gate reads `submitted` but no open PR is found for `<key>` on the target repo(s), the state is ahead of the artifacts (manual edit, or a sub-agent that died before opening its PR). Do NOT proceed as if a PR exists — post a diagnostic to the status issue and HALT.
1b. **Detect orphaned dispatch.** If `scratch/orchestrator.md` records a dispatched session for the active repo but the status issue has NO completion comment (no `LOOP-REPORT`) for it, the sub-agent died before reporting. Run the duplicate guard (close any orphan branch/PR on the target repo per Rule 4), clear that session ID from scratch, and re-dispatch — do NOT re-dispatch without clearing, or you create duplicate PRs.
2. Determine wake reason:
   - **Sub-agent handoff** (completion/failure comment with wake marker) → run `submitted → archived` step 1 (verify PR, apply `pr-review`).
   - **Human decision** (`Decision:` on status issue, human author) → run `submitted → archived` step 3.
   - **Kickoff** (`/orchestrate <key>`) → adopt the kickoff issue, run from the current gate state.
3. If woken with no actionable signal (no marker, no human decision): report the current state and go idle.

## Scratch State (orchestrator-private)

The orchestrator directly owns metarepo state that the report-only loop does not write: `gate-status.yaml` (via `/update-gate`), `status.md` (human-facing, updated at each milestone), and `scratch/orchestrator.md` (cloud bookkeeping). Write `scratch/orchestrator.md` immediately after any significant event (dispatch, wake, gate write, error) — not batched at idle, so a crashed session loses nothing. Record:
- Current lifecycle position and which repo in the sequence is active
- Session IDs of dispatched sub-agents (cloud bookkeeping)
- Pending decisions and any errors

## Error Handling

- **Dispatch failure:** document in `scratch/orchestrator.md`, close any orphan PR, do not advance the gate.
- **Loop halt reported by sub-agent:** HALT, post summary to status issue, go idle. Do not advance.
- **Ambiguous gate comment:** reply on the status issue requesting a structured `Decision:`; do not proceed.
- **Repo not in registry:** halt and report. Do not guess.
- **`$SUBAGENT_RUNTIME_ARN` unset:** halt; instruct the user to run `/multi-repo-loop <key>` locally instead.
