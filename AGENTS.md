# AGENTS.md

System of record for AI assistant guidance in this repository.

## What This Repo Is

A spec-driven multi-repo orchestration harness. This is a reusable template for managing complex, multi-repository initiatives through a unified specification and orchestration layer.

**Project: <Project name>**  
**Description:** <one-line description>  
**Stack:** <primary technology stack>  
**Repos:** See `project/project-repositories.yaml`

## Directory Structure

```
meta-repo/
├── AGENTS.md
├── README.md
├── CLAUDE.md
├── META-REPO-GUIDE.md
├── .gitignore
├── .env.acli.example
├── specs/
│   ├── README.md
│   ├── feature/.gitkeep
│   ├── bug/.gitkeep
│   ├── chore/.gitkeep
│   ├── design/.gitkeep
│   ├── planning/.gitkeep
│   └── archive/.gitkeep
├── planning/
│   └── README.md
├── project/
│   ├── README.md
│   └── project-repositories.yaml
├── architecture/
│   ├── legacy/
│   └── patterns/
├── docs/
│   └── how-to/
├── org/
├── playbooks/
├── .claude/
│   ├── commands/          # 23 slash commands
│   │   ├── scripts/       # Shell scripts for loop orchestration
│   │   └── references/    # Runtime reference docs
│   └── agents/            # 9 subagents
└── scripts/               # Validation and setup scripts
```

## Session Start

At the start of each session, load `architecture/context-index.md` if it exists for architectural context.

## Context Loading

Load `architecture/context-index.md` if it exists. If not, fall back to `architecture/README.md`. This provides architectural context for the codebase.

## Working with Specs

Specs live in `specs/<type>/<initiative>/<slice>/` with worktree convention: `specs/<type>/<initiative>/<slice>/repo/<repo-name>/`.

- **Two-level nesting** (`<initiative>/<slice>/`) for decomposed work (phases, batches)
- **One-level nesting** (`<initiative>/`) for standalone specs

Types: `feature`, `bug`, `chore`, `design`, `planning`

Each spec contains:
- `spec.yaml` — metadata, status, repos, Jira links
- `SPEC.md` — technical specification
- `repo/<repo-name>/` — per-repo worktrees for execution

## Orchestration Commands

### Planning & Specs
- `/generate-spec` — Create a new spec from description
- `/approve` — Approve a spec for execution
- `/decompose-phase` — Break a spec into phases
- `/dispatch-batch` — Dispatch work batch to worktrees
- `/plan-modernization` — Generate modernization plan
- `/generate-engineering-plan` — Generate engineering plan from spec

### Execution
- `/multi-repo-loop` — Run loop across repos
- `/update-gate` — Update feature gate status

### Post-execution
- `/finalize-spec` — Mark spec as completed
- `/archive-spec` — Archive a spec
- `/retrospective` — Generate retrospective
- `/list-specs` — List all specs with status

### Jira Integration
- `/jira-to-specs` — Import Jira issues as specs
- `/push-to-jira` — Push spec updates to Jira
- `/sync-jira` — Bidirectional sync with Jira
- `/fetch-confluence` — Fetch Confluence docs

### Repository Management
- `/register-repo` — Register a new repo
- `/promote-repo` — Promote repo status
- `/scaffold-repo` — Scaffold new repo structure
- `/init-repo` — Initialize repo with patterns
- `/repo-status` — Show repo status
- `/onboard-legacy-repo` — Onboard legacy repo

## Spec Status Lifecycle

Exact enum: `specified → planned → executed → submitted → archived`

- **specified** — Spec written, not yet approved
- **planned** — Approved, not yet started
- **executed** — Work completed in worktrees
- **submitted** — PRs created and submitted
- **archived** — Work merged and archived

## Plan Status Enum

Exact enum: `not_started | approved | in_progress | completed | on_hold | blocked`

## Repo Status Enum

Exact enum: `proposed | planned | active | legacy | archived`

- **proposed** — Candidate for creation
- **planned** — Approved, not yet created
- **active** — In active development
- **legacy** — Maintenance mode only
- **archived** — Read-only, no changes

## Local Development Tooling

### Atlassian CLI Setup

Run `./scripts/setup-atlassian.sh` to configure ACLI for Jira/Confluence integration.

Test with `./scripts/test-acli.sh` to verify configuration.

Set environment variables in `.env.acli.example` (copy to `.env.acli` and populate):
```
JIRA_BASE_URL=https://<YOUR_ORG>.atlassian.net
JIRA_USER=<your-email>
JIRA_API_TOKEN=<your-token>
CONFLUENCE_BASE_URL=https://<YOUR_ORG>.atlassian.net
CONFLUENCE_USER=<your-email>
CONFLUENCE_API_TOKEN=<your-token>
```

## Reference Documentation

- **Workflow:** See `META-REPO-GUIDE.md` for day-to-day operations
- **Memory System:** See `docs/THREE_TIER_MEMORY.md` for context persistence
- **Playbooks:** See `playbooks/` for runbook procedures

## Communication Style

Terse, technical, no filler. Direct answers. No affirmations or analogies. Start high-level and drill down when prompted. During technical discussions, assume competence and skip preamble.
