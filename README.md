# AI-Modernization Meta-Repo Harness

## What This Repo Does

- Spec-driven development workflow with lifecycle gates
- Three-tier memory system (org → project → repo → scratch)
- Multi-repo orchestration via worktrees and AOS sub-loops
- AI tool integration (slash commands, subagents, playbooks)

## Directory Structure

See `AGENTS.md` for the full directory tree and tier definitions. Key directories:

- `org/` — Org-tier platform standards
- `project/` — Project-tier context and repo configuration
- `repo/` — Repo-specific technical guidance
- `specs/` — Active specifications with embedded plans
- `context/scratch/` — Volatile working memory

## Templates

| Template | Purpose |
|----------|---------|
| `specname.spec.md` | Functional specification |
| `specname.plan.md` | Technical implementation plan |
| `repo-lifecycle.md` | Repository lifecycle process |
| `_loop-config.yaml.template` | AOS loop configuration |

## Key Documentation

| Document | Purpose |
|----------|---------|
| `AGENTS.md` | Primary AI assistant guidance |
| `META-REPO-GUIDE.md` | Day-to-day spec workflow |
| `docs/THREE_TIER_MEMORY.md` | Memory hierarchy and promotion rules |
| `docs/FRONTMATTER_STANDARDS.md` | YAML frontmatter conventions |
| `org/` | Org-tier platform standards |

## Getting Started

1. Clone this repo
2. Copy `.env.acli.example` to `.env.acli.local` and fill credentials
3. Run `./scripts/setup-atlassian.sh` (optional, for Jira/Confluence)
4. Edit `project/project-repositories.yaml` with your target repos
5. See `META-REPO-GUIDE.md` for the spec workflow
