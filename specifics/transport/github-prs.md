# Transport Binding: GitHub PRs

How the orchestrator's communication events map to GitHub. The orchestrator workflow defines abstract events; this document provides the concrete implementation.

## Core Protocol

**Control surface = the metarepo SPEC PR.**

Each spec execution maps to one metarepo spec PR on branch `spec/<type>/<key>`. That PR is the control surface for the spec's entire lifecycle: labels = lifecycle state, comments = human decisions, merge to `main` = archived.

Kickoff: a human creates metarepo branch `spec/<type>/<key>`, adds the spec, pushes, opens the **metarepo spec PR** for that branch, and wakes the orchestrator. One spec → one metarepo spec PR.

**Dispatch & companion PRs.**

Orchestrator dispatches one sub-agent per target repo. Each sub-agent runs `/multi-repo-loop <key> --repos <repo> --gates <level>` whole on branch `agent/<type>/<key>` in that code repo, and opens a **code-repo companion PR**. Multi-repo specs ⇒ N companion PRs (expected, fine).

**Companion PR Rule:** A spec is not complete until ALL PRs across ALL repos are merged. The orchestrator merges the metarepo spec PR to `main` (= archived) ONLY after all companion code PRs are merged.

## Spec Lifecycle Mapping

Lifecycle states: `specified → planned → executed → submitted → archived`

PR label taxonomy:

| Lifecycle State | PR Label | Meaning |
|---|---|---|
| `specified` | `spec-review` | Spec written, awaiting human approval to proceed |
| `planned` | `plan-review` | Execution plan ready, awaiting human approval to execute |
| `executed` | `sub-agent-complete` | Work complete in code repos, not yet submitted |
| `submitted` | `pr-review` | Companion PRs merged, awaiting final archive approval |
| `archived` | (no label) | Metarepo spec PR merged to `main` |
| N/A | `orchestrator-pause` | Generic pause state (always paired with a specific gate label) |
| N/A | `spec-complete` | All work done, summary for human (full gate only) |

## Event: Review Gate (PAUSE)

**Gate = mutate the spec PR in place (foundry Universal Rule).**

The orchestrator NEVER opens a new PR or branch for a gate. It commits any gate content to the EXISTING `spec/<type>/<key>` branch, swaps labels, and edits the PR body to the review-gate template. The human comments the decision on that same PR.

Steps:

1. Commit gate artifact (plan, summary, etc.) to the `spec/<type>/<key>` branch if needed.
2. Swap labels: remove `sub-agent-complete` (if present), add `orchestrator-pause` + the specific gate-type label:
   - `spec-review` — spec written, awaiting approval
   - `plan-review` — execution plan ready, awaiting approval
   - `pr-review` — companion PRs submitted, awaiting merge decision
   - `spec-complete` — all work done, awaiting archive approval (full gate only)
3. Edit the PR body to the review-gate template (below).
4. Go idle. Wait for human comment.

On resume: merge or close the PR (`--delete-branch` when closing), advance lifecycle step.

### Review-Gate PR Body Template

```
## Status
What was done and where things stand.

## Decision Needed
What the human needs to decide. Numbered options if applicable.

## Context
Links to artifacts — link EVERY companion code PR so reviewers know where to look (review the code diff on each companion PR) vs where to decide (comment here on the spec PR). Key metrics. What happens after response.

## How to Respond
Comment on this PR with your Decision. The orchestrator will resume automatically.
```

## Event: Approval (RESUME)

When the protocol says "check for pending review gates with human responses":

1. **Find open gates**: `gh pr list --label orchestrator-pause --state open` (searches metarepo by default).
2. **Read comments**: `gh pr view <number> --comments`
3. **Verify human author**: `gh pr view <number> --json comments --jq '.comments[].author.login'`. If login ends with `[bot]`, skip that comment — gate is NOT satisfied. Continue waiting.
4. **Interpret intent**: Read the comment and determine the human's decision by reasoning about intent — the `Decision: <verb>` schemas below are a suggested convention, not a required format. "approved", "lgtm", "ship it", "hold", "roll it back" all map to a decision. If no actionable decision is present, do not advance the gate.
5. **Act on the decision**: Execute the corresponding action (proceed, reject, hold, etc.).
6. **Close the gate** (mandatory): Use `gh pr close` for rejected specs or `gh pr merge` to archive approved specs. After merging or closing, delete the remote branch (`--delete-branch`).

## Event: Sub-Agent Complete

When a sub-agent finishes work in a code repo:

- Sub-agent adds the `sub-agent-complete` label to the metarepo spec PR via `gh pr edit <number> --add-label sub-agent-complete` — a label/comment MUTATION, NEVER a git branch push.
- Sub-agent adds an informational comment to the spec PR summarizing completion status and linking the companion code PR.
- The webhook (cloud) or orchestrator (local) picks up from there.

**Serialized dispatch (cloud).** The orchestrator dispatches ONE sub-agent (one repo) at a time and clears the `sub-agent-complete` label after handling each repo before dispatching the next. This keeps the single label unambiguous — only one sub-agent can add it at a time — and avoids the concurrent-label webhook problem (GitHub does not re-fire a `pull_request` labeled event when a label is already present, and a shared label carries no per-repo identity). One repo in flight per spec; see `/orchestrate` State Assessment.

## Event: Status Update

**Status issue = optional informational log (milestones only).**

The status issue is DEMOTED to an optional informational log, matching the foundry. It is NOT a control mechanism. Default: do NOT create one; the spec PR is the human-facing surface.

When the protocol says "post a status update" AND a status issue exists:

- Post comments at each milestone:
  - Sub-agent dispatch / completion
  - Pause gates hit / resumed
  - Quality gate results summary
  - Spec complete
- Sub-agents may also post progress comments (pass the issue number in the dispatch instruction). This is purely informational.

When the spec completes, the orchestrator closes the status issue after merging the metarepo spec PR to `main`. The issue is informational — the spec PR is the authoritative control surface.

## Companion PR Rule

A spec is not complete until ALL its PRs across ALL repos are merged. Check each sub-agent's comment on the metarepo spec PR for companion PR links. Verify all companion PRs are merged before merging the metarepo spec PR to `main` (= archived).

The orchestrator's scratch file (`specs/<type>/<initiative>/<slice>/scratch/orchestrator.md`) tracks companion PR URLs.

## Duplicate Dispatch Guard

Before dispatching, check for prior attempts:

1. Check open PRs in metarepo: `gh pr list --search "<key>" --state open`
2. Check open PRs in each target repo: `gh pr list --repo <org>/<repo> --search "<key>" --state open`
3. Check metarepo branch: `git ls-remote --heads origin 'spec/<type>/<key>'`
4. Check target repo branches: `git ls-remote --heads <target> 'agent/<type>/<key>'` (for each target repo)
5. Check status issues: `gh issue list --label spec-status --state open` (if any status issue exists)

If prior attempts exist: close PRs, delete branches, close duplicate issues. Document in scratch.

## Branch Naming

| Creator | Pattern | Example |
|---|---|---|
| Human/orchestrator (metarepo spec PR) | `spec/<type>/<key>` | `spec/feature/oauth-integration` |
| Sub-agent (code-repo companion PR) | `agent/<type>/<key>` | `agent/feature/oauth-integration` |

There is NO separate orchestrator close-out branch. Merging the spec PR to `main` IS the archival.

Before creating a branch, check if it exists (`git ls-remote --heads origin '<branch>'`). If collision, append `-v2`. After merging or closing a PR, delete the remote branch (`--delete-branch`).

## Suggested Comment Formats

These `Decision: <verb>` formats are a **suggested convention** offered to humans in gate PR bodies — they make intent unambiguous and trivial to act on. They are **NOT required**: the orchestrator interprets free-form comments by intent (see Event: Approval). Reviewers may use them or just say what they want in plain language.

### Spec Review Response
```
Decision: approved | rejected | changes_requested

[optional feedback]
```

### Plan Review Response
```
Decision: approved | rejected | changes_requested

[optional feedback or adjustment instructions]
```

### PR Review Response
```
Decision: merge | hold | rollback

[optional context]
```

### Spec Complete Response (full gate close-out only)
```
Decision: approved | changes_requested

[optional feedback]
```
`approved` → orchestrator archives (merges the spec PR to `main`). `changes_requested` → orchestrator surfaces the request and does not archive.

## Wake Events (Cloud Mode)

**Wake = Option A (metarepo is the only webhook hub).**

Webhooks fire on the METAREPO ONLY. Code repos carry no webhooks and stay "dumb".

Three wake events, all native GitHub events on the metarepo spec PR:

1. **Kickoff**: The metarepo spec PR is opened or labelled.
2. **Sub-agent handoff**: A sub-agent, on completion, adds the `sub-agent-complete` label (and an informational comment) to the metarepo spec PR via `gh` — a label/comment mutation, never a git branch push.
3. **Human decision**: A human comments on the spec PR while it is paused (carries `orchestrator-pause`). The orchestrator interprets the comment's intent — no rigid `Decision:` phrasing required.

The webhook handler (`specifics/platform/aws-agentcore/scripts/webhook-handler/`) filters for these events and invokes the orchestrator's AgentCore runtime. GitHub `issue_comment` events fire for BOTH issues and PRs, so the handler wakes the orchestrator ONLY when: the `issue` has a `pull_request` field, the PR carries the `orchestrator-pause` label (actively awaiting a decision), and the author is human (non-`[bot]`). It does NOT gate on comment text — interpreting intent is the orchestrator LLM's job. This keeps spurious wakes out (idle chatter, unrelated issues, bot comments) while accepting decisions in any phrasing.

**Local mode:** No webhooks. The orchestrator blocks on stdin or polls for comment updates (implementation TBD per `agent-runtime-local.md`).

## PR Body Examples

**Spec Review:**
```
Title: Spec review: Add OAuth integration
Labels: orchestrator-pause, spec-review

## Status
Spec drafted for OAuth 2.0 integration with Google + GitHub providers.
Spec file: specs/feature/oauth-integration/SPEC.md

## Decision Needed
Review the spec and approve to proceed with planning.

## Context
- Repos: api, web-client
- Dependencies: none
- Estimated: 3-5 days

## How to Respond
Comment on this PR with your Decision. The orchestrator will resume automatically.
```

**PR Review (per repo — serialized dispatch fires one of these per repo):**
```
Title: PR review: OAuth integration — api
Labels: orchestrator-pause, pr-review

## Status
Repo `api` complete (repo 1 of 2 for this spec). Its companion PR is open and ready for review.

## Decision Needed
Review the api companion PR and approve to merge. After merge, the orchestrator dispatches the next repo (`web-client`).

## Context
- API companion PR: org/api-repo#45 (3 new routes, 2 new middleware, 12 new tests)
- All tests passing
- Quality gate: standard (linting + tests passed)
- Remaining repos: web-client

Review the code diff on the companion PR. Comment your decision here on the spec PR.

## How to Respond
Comment on this PR with your Decision. The orchestrator will resume automatically.
```

## Error Recovery

If sub-agent dispatch fails:
1. Document failure in scratch (`specs/<type>/<initiative>/<slice>/scratch/orchestrator.md`)
2. Close the spec PR with failure summary in final comment
3. Delete the `spec/<type>/<key>` branch
4. Update spec status to `specified` (reset to pre-execution state) if needed

If a gate comment is ambiguous or missing required fields:
1. Reply with structured error comment requesting clarification
2. Do NOT proceed — wait for valid response
