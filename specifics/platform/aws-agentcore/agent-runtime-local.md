# Agent Runtime: Local CLI

How the orchestrator and sub-agents run when executing locally via Claude Code CLI.

## Components

```
Human (terminal + GitHub)
    ↕ runs orchestration commands, reviews PRs, leaves comments
Orchestrator Agent (Claude Code CLI — interactive session)
    ├── reads/writes metarepo (git)
    ├── creates PRs for pause gates (gh CLI)
    ├── dispatches sub-agents (Agent tool — in-process)
    └── reads PR comments for human decisions (gh CLI)
Sub-Agents (Agent tool — in-process)
    └── Per-repo work: feature implementation, refactoring, etc.
```

No webhook. No Lambda. No AgentCore. You are the scheduler.

## How It Works

### Orchestrator
- **Lifetime:** One CLI session. Ends when the orchestrator hits a PAUSE point or you exit.
- **Workspace:** Your local metarepo clone.
- **Auth:** Your local AWS credentials (`~/.aws/` if needed), `gh` CLI already authenticated.
- **LLM:** Anthropic API via your personal account (not Bedrock).
- **Trigger:** You run orchestration commands in the terminal (e.g., via workflow skills).

### Sub-Agents
- **Lifetime:** In-process via the Agent tool. Lives within the orchestrator's session.
- **Workspace:** Same metarepo + cloned repos in the spec's `repo/` directory.
- **Auth:** Inherits your local credentials — no IAM session scoping.
- **System prompt:** `AGENTS.md` + spec context + repo-specific instructions

### Resume Flow
1. Orchestrator hits a PAUSE point → creates a review-gate PR → session ends.
2. You get a GitHub notification (email, mobile, whatever).
3. You review the PR, leave a comment with your decision.
4. You re-run the orchestration command in the terminal.
5. Orchestrator reads the PR comment, picks up where it left off.

## Differences from Cloud Runtime

| Aspect | Cloud (AgentCore) | Local (CLI) |
|---|---|---|
| Orchestrator lifetime | Persistent session, survives idle | One session per CLI invocation |
| Sub-agent dispatch | `dispatch_subagent.py` → AgentCore API | Agent tool (in-process) |
| Wake-up | GitHub webhook → Lambda → invoke-agent | You re-run orchestration command |
| LLM backend | Bedrock (`CLAUDE_CODE_USE_BEDROCK=1`) | Anthropic API (your account) |
| Auth | Per-session STS-scoped IAM roles | Your local credentials |
| Session isolation | Separate containers, separate IAM | Shared process, shared credentials |
| Cost | ~$20-35/spec (Bedrock tokens + compute) | Your monthly Anthropic budget |

## Environment Detection

The orchestrator detects execution mode by checking for `SUBAGENT_RUNTIME_ARN`:

```python
import os

if os.environ.get("SUBAGENT_RUNTIME_ARN"):
    # Cloud mode — dispatch via AgentCore API
    from scripts.dispatch_subagent import dispatch
    session_id = dispatch(prompt=prompt)
else:
    # Local mode — dispatch via Agent tool (in-process)
    # Use the Agent tool to spawn sub-agent
```

When `SUBAGENT_RUNTIME_ARN` is unset (local mode), the orchestrator uses the Claude Code Agent tool to spawn sub-agents in-process.

## Prerequisites

- Claude Code CLI installed and authenticated
- `gh` CLI authenticated with GitHub (scopes: `repo`, `read:org`, `workflow`)
- Git configured with your credentials
- AWS CLI configured (if accessing AWS resources)
- Python 3.9+ for running validation scripts

## Protocol Parity

The PR-based communication protocol is identical between cloud and local modes:
- Same PR lifecycle (one PR per spec, labels as state markers)
- Same comment schema (structured decisions, wake patterns)
- Same pause gates (orchestrator creates review-gate PR, waits for human decision)

The only difference: in local mode, you are the wake mechanism. In cloud mode, the GitHub webhook Lambda wakes the orchestrator automatically.
