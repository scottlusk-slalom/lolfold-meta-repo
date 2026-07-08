# Transport Binding: GitHub PRs

How the orchestrator's communication events map to GitHub. The orchestrator workflow defines abstract events; this document provides the concrete implementation.

## Core Protocol

**One PR per spec execution.** Each spec gets a single PR that progresses through lifecycle states via label mutations. The PR tracks the spec's journey from planning through submission.

## Spec Lifecycle Mapping

The template's spec lifecycle: `specified → planned → executed → submitted → archived`

PR label taxonomy:

| Lifecycle State | PR Label | Meaning |
|---|---|---|
| `specified` | `spec-review` | Spec written, awaiting human approval to proceed |
| `planned` | `plan-review` | Execution plan ready, awaiting human approval to execute |
| `executed` | `sub-agent-complete` | Work complete in worktrees, not yet submitted |
| `submitted` | `pr-review` | PRs created in target repos, awaiting merge |
| N/A | `orchestrator-pause` | Generic pause state (always paired with a specific gate label) |

## Event: Review Gate (PAUSE)

There are two kinds of gates depending on when they fire in the lifecycle:

### Pre-Execution Gates (orchestrator-initiated)

`spec-review` and `plan-review` happen BEFORE sub-agents are dispatched. There is no sub-agent PR to mutate. The orchestrator creates its own PR:

1. Create branch: `orchestrator/{spec-type}/{spec-name}/review`
2. Commit the artifact being reviewed (spec file for `spec-review`, plan file for `plan-review`) to the branch.
3. Open PR with labels: `orchestrator-pause` + gate type (`spec-review` or `plan-review`).
4. Set PR body to the review-gate template (below).
5. Go idle. Wait for human comment.

On resume: merge or close the PR (`--delete-branch`), then proceed with next lifecycle step.

### Post-Execution Gates (mutates sub-agent PR)

`pr-review`, quality gates (`gate-*-review`), and `spec-complete` happen AFTER sub-agents have produced work. The sub-agent already opened a PR with the `sub-agent-complete` label on branch `agent/{spec-type}/{spec-name}/{repo}`. The orchestrator mutates that PR in place:

1. Swap labels: remove `sub-agent-complete`, add `orchestrator-pause` + the specific gate type label:
   - `gate-minimal-review` — minimal quality gate requires human decision
   - `gate-standard-review` — standard quality gate requires human decision
   - `gate-full-review` — full quality gate requires human decision
   - `pr-review` — PRs submitted, awaiting merge approval
   - `spec-complete` — all work done, summary for human
2. Edit the PR body to the review-gate template (below).
3. Go idle. Wait for human comment.

On resume: merge or close the PR (`--delete-branch`), advance spec status.

### Review-Gate PR Body Template

```
## Status
What was done and where things stand.

## Decision Needed
What the human needs to decide. Numbered options if applicable.

## Context
Links to artifacts (PRs, logs, validation output). Key metrics. What happens after response.

## How to Respond
Leave a comment on this PR with your decision. The orchestrator will resume automatically.
```

## Event: Approval (RESUME)

When the protocol says "check for pending review gates with human responses":

1. **Find open gates**: `gh pr list --label orchestrator-pause --state open`
2. **Read comments**: `gh pr view <number> --comments`
3. **Verify human author**: `gh pr view <number> --json comments --jq '.comments[].author.login'`. If the only comments are from the bot identity, the gate is NOT satisfied — go idle.
4. **Parse the response**: Read the comment to understand the decision.
5. **Close the gate** (mandatory): Use `gh pr close` for consumed pause PRs or `gh pr merge` for PRs with spec changes. After merging or closing, delete the remote branch (`--delete-branch`).

## Event: Status Update

When the protocol says "post a status update":

- On spec creation, create a GitHub Issue titled `Status: {spec-type}/{spec-name}` with label `spec-status`.
- Post comments at each milestone:
  - Sub-agent dispatch / completion
  - Pause gates hit / resumed
  - Quality gate results summary
  - Spec complete
- Sub-agents also post progress comments (pass the issue number in the dispatch instruction). This is purely informational — not a control mechanism.

When the spec completes, the orchestrator closes the status issue after opening the completion PR. The issue is informational — the completion PR is the authoritative close-out artifact.

## Event: Sub-Agent Complete

When a sub-agent finishes spec work:

- Sub-agent opens a PR with the `sub-agent-complete` label (`gh pr create --label sub-agent-complete`)
- The webhook (cloud) or orchestrator (local) picks up from there

## Companion PR Rule

A spec is not complete until ALL its PRs across ALL repos are merged. Check the sub-agent's PR body for companion PR links. Merge or verify all are merged before updating spec status to `archived`.

The orchestrator's scratch file (`specs/<type>/<initiative>/<slice>/scratch/orchestrator.md`) tracks companion PR URLs.

## Duplicate Dispatch Guard (GitHub-specific checks)

Before dispatching, check for prior attempts:
- Check open PRs: `gh pr list --search "{spec-name} {spec-type}" --state open`
- Check branches: `git ls-remote --heads origin agent/{spec-type}/{spec-name}/*`
- Check status issues: `gh issue list --label spec-status --state open`
- If prior attempts exist: close PRs, delete branches, close duplicate issues. Document in scratch.

## Branch Naming

| Creator | Pattern | Example |
|---|---|---|
| Sub-agent (metarepo PR) | `agent/{spec-type}/{spec-name}/{repo}` | `agent/feature/oauth-integration/api` |
| Sub-agent (work repo PR) | `agent/{spec-type}/{spec-name}` | `agent/feature/oauth-integration` |
| Orchestrator (close-out) | `orchestrator/{spec-type}/{spec-name}/complete` | `orchestrator/feature/oauth-integration/complete` |

There is no separate orchestrator branch for review gates. Gates mutate the sub-agent's existing metarepo PR on `agent/{spec-type}/{spec-name}/{repo}`. The only orchestrator-owned branch is `orchestrator/{spec-type}/{spec-name}/complete` for the close-out PR.

Before creating a branch, check if it exists (`git ls-remote --heads origin {branch}`). If collision, append `-v2`. After merging or closing a PR, delete the remote branch (`--delete-branch`).

## Quality Gate Integration

The template's quality gate system (`minimal`, `standard`, `full`) maps to human review checkpoints:

- **minimal**: automated only, no pause
- **standard**: pause at plan-review + pr-review
- **full**: pause at spec-review + plan-review + pr-review + spec-complete

Gate configuration is in `spec.yaml` field: `quality_gate: minimal | standard | full`

When a quality gate requires human review, the orchestrator:
1. Adds the `orchestrator-pause` label
2. Adds the gate-specific label (e.g., `gate-standard-review`)
3. Waits for human comment on the PR
4. Resumes after parsing the decision

## Structured Comment Schemas

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

### Gate Review Response (standard/full)
```
Decision: proceed | retry | abort

[optional instructions for retry, or reason for abort]
```

## PR Examples

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
Comment "approved" to proceed, or list specific changes needed.
```

**Plan Review:**
```
Title: Plan review: OAuth integration execution plan
Labels: orchestrator-pause, plan-review

## Status
Execution plan complete. Work decomposed into 2 repos: api (passport.js setup), web-client (OAuth button + callback).
Plan file: specs/feature/oauth-integration/scratch/plan.md

## Decision Needed
Review the plan and approve to begin execution.

## Context
- API changes: 3 new routes, 2 new middleware
- Web changes: 1 new component, OAuth callback handler
- Quality gate: standard (includes PR review)

## How to Respond
Comment "approved" to dispatch sub-agents, or request changes.
```

**Gate Failure (standard):**
```
Title: Gate failure: standard quality gate — OAuth integration
Labels: orchestrator-pause, gate-standard-review

## Status
Execution complete. 2/3 gate checks passed.
- Tests: passed (12 new tests, 100% coverage)
- Linting: passed
- Security scan: FAILED (1 medium-severity finding)

## Decision Needed
Finding: Hardcoded redirect URI in development config
1. Move redirect URI to environment variable and retry
2. Add exception to security policy and proceed
3. Abort and revise spec

## Context
- API PR: #45 (ready except for security finding)
- Web PR: #46 (ready)

## How to Respond
Comment with the option number or describe an alternative.
```

**Spec Complete:**
```
Title: Spec complete: OAuth integration
Labels: orchestrator-pause, spec-complete

## Status
All work complete. PRs merged.
- API PR: #45 (merged)
- Web PR: #46 (merged)
- Tests: 12 new, all passing
- Docs: OAuth setup guide added

Merge this PR to archive the spec.
```

## Wake Events (Cloud Mode)

When running in cloud mode (AgentCore), the orchestrator goes idle after opening a pause PR. GitHub webhooks trigger re-dispatch:

**Wake triggers:**
- Comment added to PR with `orchestrator-pause` label
- PR with `orchestrator-pause` label closed or merged

The webhook handler (`specifics/platform/aws-agentcore/scripts/webhook-handler/`) filters for these events and invokes the orchestrator's AgentCore runtime.

**Local mode:** No webhooks. The orchestrator blocks on stdin or polls for comment updates (implementation TBD per `agent-runtime-local.md`).

## Error Recovery

If sub-agent dispatch fails:
1. Document failure in scratch (`specs/<type>/<initiative>/<slice>/scratch/orchestrator.md`)
2. Close the PR with failure summary in final comment
3. Delete the branch
4. Update spec status to `specified` (reset to pre-execution state)

If a gate comment is ambiguous or missing required fields:
1. Reply with structured error comment requesting clarification
2. Do NOT proceed — wait for valid response

## Multi-Repo Coordination

For specs touching multiple repos:

1. Sub-agent creates one PR per repo (in the target work repos)
2. Sub-agent opens one metarepo PR linking all companion PRs
3. Orchestrator waits for ALL companion PRs to be merged before marking spec `archived`
4. Companion PR links are tracked in metarepo PR body and orchestrator scratch

Example metarepo PR body:
```
## Companion PRs
- api: org/api-repo#45
- web-client: org/web-client#46

Do not merge this PR until all companion PRs are merged.
```
