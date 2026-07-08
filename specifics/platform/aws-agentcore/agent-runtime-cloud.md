# Agent Runtime: Cloud Execution via AgentCore

Operational instructions for cloud-based multi-repo spec execution using AWS Bedrock AgentCore.

## Architecture

```
Human (GitHub)
    ↕ reviews PRs, leaves comments
Orchestrator Agent (AgentCore Runtime — persistent session)
    ├── reads/writes metarepo (git)
    ├── creates PRs for pause gates (gh CLI)
    ├── dispatches sub-agents (AgentCore Runtime — ephemeral sessions)
    └── reads PR comments for human decisions (gh CLI)
Sub-Agents (AgentCore Runtime — ephemeral)
    ├── Per-repo work: feature implementation, refactoring, etc.
    └── Sequential execution (one repo at a time)
GitHub Webhook (Lambda)
    └── PR comment event → wakes orchestrator via invoke-agent-runtime
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
  - `ORCHESTRATOR_SESSION_ID` — set by orchestrator to pin sub-agent parent context
  - `CLAUDE_CODE_USE_BEDROCK=1` — forces Bedrock LLM backend
  - `AWS_REGION` — region for Bedrock and AgentCore
  - `GITHUB_PAT` — loaded from Secrets Manager for gh CLI auth

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
  - Read/write to metarepo (GitHub via PAT)
  - Dispatch AgentCore sessions (sub-agents)
  - GitHub API (create PRs, read comments, manage labels)
  - S3 read/write for session state
- **Trigger:** 
  - GitHub webhook (PR comment) → Lambda → `invoke-agent-runtime`
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
  - Metarepo clone (read-only for spec context)
  - Target repo worktree clone (read-write)
- **IAM scope:**
  - Scoped to the spec's context (only S3 paths, resources for that spec if applicable)
  - GitHub API (read metarepo, read/write target repo)
  - S3 read/write for artifacts
- **Trigger:** Dispatched by orchestrator via `dispatch_subagent.py` → AgentCore API
- **System prompt:** `AGENTS.md` + spec context + repo-specific instructions
- **Parent pinning:** Receives `ORCHESTRATOR_SESSION_ID` to maintain context lineage

## Environment Detection

The key gate for cloud vs local execution:

```python
import os

if os.environ.get("SUBAGENT_RUNTIME_ARN"):
    # Cloud mode — dispatch via AgentCore API
    from scripts.dispatch_subagent import dispatch
    session_id = dispatch(prompt=prompt, status_issue=issue_num)
else:
    # Local mode — dispatch via Agent tool (in-process)
    # See agent-runtime-local.md
```

Set by the orchestrator runtime at startup. Sub-agents inherit this and can re-dispatch if needed.

## Event Flow

### Happy Path (multi-repo spec)

```
1.  Human invokes orchestrator: "Implement feature X across api-repo and frontend-repo"
2.  Orchestrator: reads spec, validates repos listed in spec.yaml
3.  Orchestrator: dispatches sub-agent for api-repo
4.  Sub-agent (api-repo): clones repo worktree, implements feature, commits, opens PR
5.  Orchestrator: wakes on sub-agent completion, reviews PR
6.  → PAUSE: creates review-gate PR on metarepo/specs/feature/X/submitted
    Human gets GitHub notification, reviews diff, comments "approved"
7.  GitHub webhook → Lambda → invoke-agent-runtime: wakes orchestrator
8.  Orchestrator: reads PR comment, merges sub-agent PR, advances spec status
9.  Orchestrator: dispatches sub-agent for frontend-repo
10. Sub-agent (frontend-repo): clones repo worktree, implements feature, commits, opens PR
11. Orchestrator: wakes on sub-agent completion, reviews PR
12. → PAUSE: creates final review-gate PR
    Human reviews, comments "approved"
13. Orchestrator: merges PR, advances spec to archived, generates retrospective
```

### Failure Path

```
1. Sub-agent fails (timeout, infra error, etc.)
2. Orchestrator: reads PR or sub-agent logs, identifies issue
3. → PAUSE: creates PR with error details and suggested fix
   Human reviews, comments with decision
4. Orchestrator wakes: adjusts spec/guidance, re-dispatches
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
- `secretsmanager:GetSecretValue` — GitHub PAT (same as orchestrator)
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

### Phase 2: Webhook Automation
- Lambda function: GitHub webhook receiver → `invoke-agent-runtime` (wake orchestrator on PR comments)
- API Gateway: webhook endpoint with GitHub signing secret verification
- GitHub webhook configuration on metarepo (PR comment events)
- Session ID mapping: how Lambda knows which AgentCore session to wake (PR labels or DynamoDB)

### Phase 3: Operational Tooling
- CloudWatch dashboards (token usage, session durations, error rates)
- Cost tracking (tag sessions with spec ID for cost allocation)
- Timeout handling (sub-agent didn't finish in X minutes)
- Multi-spec concurrency (orchestrator manages multiple active specs)
