# Agent Runtime: Cloud Execution via AgentCore

Operational instructions for cloud-based multi-repo spec execution using AWS Bedrock AgentCore.

## Architecture

```
Human (GitHub)
    ↕ reviews spec PRs, leaves Decision: comments
Orchestrator Agent (AgentCore Runtime — persistent session)
    ├── reads/writes metarepo spec PR branch spec/<type>/<key> (git)
    ├── mutates spec PR in place for gate transitions (gh CLI)
    ├── dispatches sub-agents (AgentCore Runtime — ephemeral sessions)
    └── reads spec PR comments for human decisions (gh CLI)
Sub-Agents (AgentCore Runtime — ephemeral)
    ├── Per-repo work: feature implementation, refactoring, etc.
    ├── Opens code-repo companion PR on agent/<type>/<key>
    └── Labels metarepo spec PR "sub-agent-complete" via gh (write scope required)
GitHub Webhook (Lambda) — configured on METAREPO only
    └── Spec PR events (opened / sub-agent-complete label / Decision: comment) → wakes orchestrator via invoke-agent-runtime
```

## AWS Services Used

| Service | Role |
|---|---|
| AgentCore Runtime | Hosts orchestrator (persistent) and sub-agents (ephemeral). Claude Agent SDK in Docker containers, Bedrock as LLM backend. |
| Bedrock (Claude) | LLM for both orchestrator and sub-agents (via `CLAUDE_CODE_USE_BEDROCK=1`) |
| S3 | AgentCore session storage, artifacts |
| Lambda | GitHub webhook receiver → invokes AgentCore to wake orchestrator |
| API Gateway | GitHub webhook endpoint |
| IAM (STS) | Per-session scoped credentials |
| ECR | Container images for agent runtimes |
| VPC | **Consumer project's existing VPC** — agent runtimes deploy into private subnet |

## Agent Runtime Stack

Both orchestrator and sub-agents run the same stack:

```
AgentCore Runtime (ARM64 microVM)
  └── Docker container (from ECR)
        ├── FastAPI server on :8080 (/invocations, /ping)
        ├── Claude Agent SDK (ClaudeSDKClient)
        │     ├── setting_sources = ["project"]  ← loads CLAUDE.md, skills, hooks
        │     ├── permission_mode = "bypassPermissions"
        │     └── LLM calls → Bedrock
        └── Tools: git, python, pip, aws cli, gh
```

### Container Requirements

- **Platform:** ARM64 (AgentCore microVMs are ARM)
- **User:** Non-root user required (Agent SDK refuses `bypassPermissions` as root)
- **Base image:** Recommended `public.ecr.aws/amazonlinux/amazonlinux:2023-arm64` or similar
- **Tools to bundle:**
  - `git` — metarepo and target repo clones
  - `gh` — GitHub CLI for PR operations
  - `python3` + `pip` — Agent SDK, boto3
  - `aws` CLI — S3, IAM, AgentCore API
- **Environment variables:**
  - `SUBAGENT_RUNTIME_ARN` — set by orchestrator runtime to enable cloud dispatch
  - `DISPATCHED_BY_ORCHESTRATOR` — set on EVERY dispatched sub-agent (the dispatch script always emits payload `dispatched_by_orchestrator: true`); never set in a top-level/orchestrator session. Presence is the authoritative "I am a dispatched sub-agent" signal for the `/multi-repo-loop` cloud guard.
  - `ORCHESTRATOR_SESSION_ID` — the dispatching orchestrator's session ID, for parent-context pinning. Present only when the orchestrator's own env carried it (optional); do NOT use it as the dispatched-sub-agent signal — that is `$DISPATCHED_BY_ORCHESTRATOR`.
  - `SPEC_PR` — metarepo spec PR number to label on completion (exported from the dispatch payload's `spec_pr`)
  - `STATUS_ISSUE` — optional status issue number for informational comments (exported from the dispatch payload's `status_issue` when present)
  - `CLAUDE_CODE_USE_BEDROCK=1` — forces Bedrock LLM backend
  - `AWS_REGION` — region for Bedrock and AgentCore
  - `GITHUB_PAT` — loaded from Secrets Manager for gh CLI auth
  - **Runtime entrypoint requirement:** `agent.py` MUST export dispatch payload fields as environment variables before invoking the Agent SDK: `dispatched_by_orchestrator` → `$DISPATCHED_BY_ORCHESTRATOR`, `spec_pr` → `$SPEC_PR`, `orchestrator_session_id` → `$ORCHESTRATOR_SESSION_ID` (when present), `status_issue` → `$STATUS_ISSUE` (when present). This export enables the `/multi-repo-loop` cloud guard (`$DISPATCHED_BY_ORCHESTRATOR` set ⇒ dispatched sub-agent) and completion-label step (`gh pr edit $SPEC_PR ...`); without it the guard cannot distinguish dispatched sub-agents from top-level sessions and would recurse.

## Network Configuration

### VPC Deployment Requirements

Agent runtimes MUST deploy into the consumer project's **existing VPC** with the following:

- **Private subnet** with NAT gateway for outbound internet access
- **Security group** allowing outbound HTTPS (443) to:
  - Bedrock endpoints (`bedrock-agentcore.*.amazonaws.com`, `bedrock-runtime.*.amazonaws.com`)
  - GitHub API (`api.github.com`)
  - ECR (`*.dkr.ecr.*.amazonaws.com`)
  - S3 gateway endpoint (no internet egress needed if VPC gateway configured)
- **No inbound access required** (orchestrator wakes via AgentCore API, not network connections)

### VPC Endpoint Recommendations

For cost optimization and reliability:
- S3 gateway endpoint (free, no data transfer charges)
- Bedrock interface endpoint (reduces NAT costs for high token volume)

## Session Types

### Orchestrator Session (persistent)

**Purpose:** Long-running coordinator that manages spec lifecycle and dispatches sub-agents.

- **Lifetime:** Hours to days. Survives idle periods via AgentCore session storage.
- **Session ID format:** `orchestrator-spec-{spec-type}-{initiative-name}`
  - Example: `orchestrator-spec-feature-user-auth`
- **Workspace:** 
  - Metarepo clone at `/mnt/workspace` (persistent filesystem)
  - Execution logs, pending decision state
- **IAM scope:**
  - Read/write to metarepo (GitHub via PAT) — orchestrator is sole git-writer to spec/<type>/<key> branch
  - Dispatch AgentCore sessions (sub-agents)
  - GitHub API (create/mutate spec PRs, read comments, manage labels)
  - S3 read/write for session state
- **Trigger (Wake Option A — metarepo-only webhook):**
  - GitHub webhook fires on METAREPO spec PR events: (1) spec PR opened, (2) `sub-agent-complete` label added to spec PR, (3) human comment with `Decision:` prefix on spec PR
  - Lambda receives webhook → `invoke-agent-runtime`
  - Manual CLI invocation via AgentCore console
- **System prompt:** `AGENTS.md` + relevant workflow instructions
- **Idle timeout:** Configurable (default 5 min). Session stops but can resume with filesystem intact.
- **Max lifetime:** 8 hours per cycle (resets on resume)

### Sub-Agent Session (ephemeral)

**Purpose:** Execute work within a single target repository for a specific spec.

- **Lifetime:** Minutes to hours. Dies when repo work completes.
- **Session ID format:** `subagent-{spec-id}-{repo-name}-{timestamp}`
  - Example: `subagent-feature-user-auth-api-repo-20260707T143022Z`
- **Workspace:**
  - Metarepo clone — committed specs are read-only *inputs*; sub-agent WRITES to metarepo only via `gh` label/comment on the spec PR (see IAM below)
  - Target repo worktree clone (read-write) — sub-agent's primary write surface on branch `agent/<type>/<key>`
  - **Provisioning requirement:** sub-agent needs `repos/<repo>` reference-clone layout (setup-worktree.sh expects `git -C repos/<repo> worktree add ...`); if absent, worktree step fails with "Reference clone not found"
- **IAM scope:**
  - Scoped to the spec's context (only S3 paths, resources for that spec if applicable)
  - GitHub API — **CRITICAL:** sub-agent token needs WRITE access to METAREPO for label+comment operations on the spec PR (specifically: add `sub-agent-complete` label + post completion comment). Read/write target code repo.
  - S3 read/write for artifacts
- **Trigger:** Dispatched by orchestrator via `dispatch_subagent.py` → AgentCore API
- **System prompt:** `AGENTS.md` + spec context + repo-specific instructions
- **Parent pinning:** Receives `ORCHESTRATOR_SESSION_ID` to maintain context lineage. Optional `STATUS_ISSUE` for informational comments (not required; the metarepo spec PR is the control surface).

## Environment Detection

The key gate for cloud vs local execution:

```python
import os

if os.environ.get("SUBAGENT_RUNTIME_ARN"):
    # Cloud mode — dispatch via AgentCore API
    from scripts.dispatch_subagent import dispatch
    # Pass spec PR number (required) so sub-agent knows which metarepo spec PR to label on completion
    # status_issue is optional/informational
    session_id = dispatch(prompt=prompt, spec_pr=spec_pr_number)
else:
    # Local mode — dispatch via Agent tool (in-process)
    # See agent-runtime-local.md
```

Set by the orchestrator runtime at startup. Sub-agents inherit this and can re-dispatch if needed.

## Event Flow

### Happy Path (multi-repo spec)

```
1.  Orchestrator creates metarepo spec PR on branch spec/<type>/<key> (kickoff)
2.  GitHub webhook fires (spec PR opened) → wakes orchestrator
3.  Orchestrator: reads spec, validates repos listed in spec.yaml
4.  Orchestrator: dispatches sub-agent for api-repo (passes spec key, target repo, spec PR number)
5.  Sub-agent (api-repo): clones repo worktree, runs /multi-repo-loop <key> --repos api-repo --gates <level>, implements feature, commits, opens code-repo companion PR on branch agent/<type>/<key>
6.  Sub-agent: on completion, adds `sub-agent-complete` LABEL to metarepo spec PR + informational comment via gh CLI (never git-pushes to metarepo)
7.  GitHub webhook fires (sub-agent-complete label added to spec PR) → wakes orchestrator
8.  Orchestrator: reviews companion PR, mutates spec PR in place to `pr-review` gate (commits gate/plan/status to spec/<type>/<key> branch)
9.  → PAUSE: spec PR now shows `orchestrator-pause` label
    Human gets GitHub notification, reviews companion PR diff, comments "Decision: approved" on spec PR
10. GitHub webhook fires (Decision: comment on spec PR) → wakes orchestrator
11. Orchestrator: merges api-repo companion PR, dispatches sub-agent for frontend-repo
12. Sub-agent (frontend-repo): clones repo worktree, implements feature, commits, opens companion PR
13. Sub-agent: adds `sub-agent-complete` label to metarepo spec PR + comment
14. GitHub webhook fires → wakes orchestrator
15. Orchestrator: reviews companion PR, mutates spec PR to `pr-review` gate
16. → PAUSE: Human reviews, comments "Decision: approved"
17. Orchestrator: merges frontend-repo companion PR, merges metarepo spec PR to main (= archived), generates retrospective
```

### Failure Path

```
1. Sub-agent fails (timeout, infra error, etc.)
2. Orchestrator wakes (sub-agent-complete label or timeout), reads sub-agent logs, identifies issue
3. → PAUSE: mutates spec PR to error gate with details and suggested fix, adds `orchestrator-pause` label
   Human reviews, comments "Decision: <guidance>" on spec PR
4. GitHub webhook fires (Decision: comment) → orchestrator wakes, adjusts spec/guidance, re-dispatches
```

## Manual Invocations

When manually invoking the orchestrator via the AgentCore console, you MUST pass the correct session ID to maintain continuity with webhook-driven sessions.

**Session ID format:** `orchestrator-spec-{spec-type}-{initiative-name}`

Example: for the `feature/user-auth` spec, use session ID `orchestrator-spec-feature-user-auth`.

If you use a random or default session ID, the console invocation will start a fresh session with no context from prior webhook-driven interactions.

**Note:** This is a documentation workaround. The console tooling does not currently enforce session ID format.

## IAM Roles

### Orchestrator Role

Trust policy: AgentCore service principal

Permissions:
- `bedrock:InvokeAgentRuntime` — dispatch sub-agents
- `bedrock:GetAgentRuntimeSession` — check sub-agent status
- `s3:GetObject`, `s3:PutObject` — session state, artifacts
- `secretsmanager:GetSecretValue` — GitHub PAT, other secrets
- `ecr:GetAuthorizationToken`, `ecr:BatchGetImage` — pull agent images
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` — CloudWatch logs

Inline policy for GitHub API via HTTPS (no AWS service, just outbound internet via NAT)

### Sub-Agent Role

Trust policy: AgentCore service principal

Permissions:
- `s3:GetObject`, `s3:PutObject` — scoped to spec artifacts path (e.g., `s3://bucket/specs/feature/user-auth/*`)
- `secretsmanager:GetSecretValue` — GitHub PAT (same as orchestrator) with **repo write scope** to METAREPO for label+comment operations on spec PR, plus read/write to target code repo
- `ecr:GetAuthorizationToken`, `ecr:BatchGetImage` — pull agent images
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` — CloudWatch logs

**No AgentCore dispatch permission** — sub-agents cannot spawn other sub-agents (only orchestrator can)

## Secrets

Store in AWS Secrets Manager, injected into runtime at startup:

- `github-pat` — Personal access token for gh CLI (scopes: `repo`, `read:org`, `workflow`)
- Additional secrets as needed for downstream integrations (Jira, Confluence, etc.)

## Cost Considerations

Per-spec estimates (typical feature implementation):
- Bedrock tokens: ~$15-25 (orchestrator + 2 sub-agents, ~500K tokens total)
- AgentCore compute: ~$5-10 (orchestrator 2 hours idle + wake, 2 sub-agents 30 min each)
- Data transfer: <$1 (NAT gateway egress for GitHub API)

**Total:** ~$20-35 per spec with 2 repos and 1 revision cycle

Optimizations:
- Use VPC endpoints for Bedrock to eliminate NAT charges
- Tune orchestrator idle timeout (shorter = less cost, more wake latency)
- Batch multiple specs into one orchestrator session if throughput matters

## Infrastructure to Deploy

### Phase 1: Core Runtime
- Docker container image (ARM64): Claude Agent SDK + FastAPI + tools (git, python, aws, gh)
- AgentCore Runtime definition (CDK/Terraform): orchestrator (persistent, VPC mode, session storage)
- AgentCore Runtime template: sub-agents (ephemeral, VPC mode)
- IAM roles: orchestrator role, sub-agent role template
- ECR repository for agent container images
- Agent entrypoint (`agent.py`): FastAPI wrapping ClaudeSDKClient

### Phase 2: Webhook Automation (Wake Option A)
- Lambda function: GitHub webhook receiver → `invoke-agent-runtime` (wake orchestrator on spec PR events)
- API Gateway: webhook endpoint with GitHub signing secret verification
- GitHub webhook configuration on **METAREPO ONLY** — wake triggers: (1) spec PR opened, (2) `sub-agent-complete` label added to spec PR, (3) comment on spec PR containing `Decision:` prefix. **Note:** GitHub `issue_comment` events fire for both issues and PRs; the Lambda handler must filter `issue_comment` events to only those where the event payload's `issue` object has a `pull_request` field AND the comment body contains `Decision:` — otherwise ignore.
- Session ID mapping: how Lambda knows which AgentCore session to wake (spec PR branch name `spec/<type>/<key>` → session ID `orchestrator-spec-<type>-<key>`, or DynamoDB)

### Phase 3: Operational Tooling
- CloudWatch dashboards (token usage, session durations, error rates)
- Cost tracking (tag sessions with spec ID for cost allocation)
- Timeout handling (sub-agent didn't finish in X minutes)
- Multi-spec concurrency (orchestrator manages multiple active specs)
