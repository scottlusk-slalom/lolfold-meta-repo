# Meta-Repo Module

A ready-to-use meta-repository structure for managing multi-repo project work with AI coding assistants. This module provides a spec-driven development workflow with built-in support for Claude Code, GitHub Copilot, and Cursor.

## What Is a Meta-Repo?

A meta-repo is a coordination layer that sits above your code repositories. It provides:

- **Spec-driven workflow** — Organize work into specs (feature, bug, chore, design, planning) with functional specs and technical plans
- **Three-tier memory** — Structured context at org, project, and repo levels plus volatile scratch memory
- **Multi-repo coordination** — Clone relevant repos into spec directories, work across them, and track progress in one place
- **AI tool integration** — Commands, prompts, and rules for Claude Code, GitHub Copilot, and Cursor

## When to Use This

Use a meta-repo when:

- You work across **multiple repositories** and need a coordination layer
- You want **structured specs and plans** for tracking work
- You use **AI coding assistants** and want them to understand your project context
- You need a **repeatable pattern** for onboarding new team members or AI agents

You probably don't need this if:

- You work in a **single repository** — consider the [spec-driven-development](../spec-driven-development/) module instead
- You only need **scratch memory management** — see [scratch-management-utilities](../scratch-management-utilities/)

## Quick Start

### Option A: Copy the Directory

The simplest approach — copy the entire `meta-repo/` directory to your desired location:

```bash
cp -r path/to/ae-toolkit/meta-repo/ ~/projects/my-meta-repo/
cd ~/projects/my-meta-repo/
git init
```

Then customize:
1. Edit `AGENTS.md` — fill in the "Your Project" and "Communication Style" sections
2. Edit `project/project-repositories.yaml` — add your repositories
3. Start creating specs with `/new-spec` (Claude Code) or the equivalent prompt

### Option B: Use the Bootstrap Script

```bash
# All tools (Claude Code + Copilot + Cursor)
./scripts/bootstrap.sh --target-path ~/projects/my-meta-repo

# Specific tools only
./scripts/bootstrap.sh --target-path ~/projects/my-meta-repo --tools claude-code,copilot

# With project name (replaces placeholders)
./scripts/bootstrap.sh --target-path ~/projects/my-meta-repo --project-name "My Project"
```

PowerShell:
```powershell
.\scripts\Bootstrap.ps1 -TargetPath ~\projects\my-meta-repo -Tools claude-code,copilot
```

### Option C: Via the ae-toolkit Quick-Start Script

```bash
# Include meta-repo when initializing a project
./getting-started/scripts/quick-start.sh --include-metarepo
```

## Directory Structure

```
meta-repo/
├── .claude/commands/          # Claude Code slash commands
├── .github/
│   ├── copilot-instructions.md
│   └── prompts/               # GitHub Copilot prompt files
├── .cursor/rules/             # Cursor rules
├── .gitignore
├── AGENTS.md                  # Primary AI assistant instructions
├── CLAUDE.md                  # Points to AGENTS.md
├── architecture/              # C4 architecture documentation
├── docs/
│   ├── THREE_TIER_MEMORY.md   # Memory system documentation
│   ├── FRONTMATTER_STANDARDS.md
│   └── templates/             # 9 templates for specs, plans, PRDs, etc.
├── project/                   # Product briefs, project plans, repo config
├── requirements/              # PRDs with embedded test plans
├── specs/                     # Spec directories organized by type
│   ├── bug/
│   ├── chore/
│   ├── design/
│   ├── feature/
│   └── planning/
└── scripts/                   # Bootstrap scripts
```

## AI Tool Support

The module includes integrations for three AI coding assistants. Use whichever tools your team uses — skip the rest.

| Tool | Directory | What's Included |
|------|-----------|-----------------|
| **Claude Code** | `.claude/commands/` | 5 slash commands (`/new-spec`, `/list-specs`, `/sync-repo`, `/analyze-scratch`, `/archive-spec`) |
| **GitHub Copilot** | `.github/prompts/` + `copilot-instructions.md` | 5 prompt files + repository-level instructions |
| **Cursor** | `.cursor/rules/` | 2 rule files (spec management, spec type selection) |

If you don't use one of these tools, simply delete its directory. The meta-repo works fine without any of them — they're conveniences, not requirements.

## Templates

Nine templates are included in `docs/templates/`:

| Template | Purpose |
|----------|---------|
| `specname.spec.md` | Functional specification |
| `specname.plan.md` | Technical implementation plan |
| `product-brief.md` | Stable product context |
| `project-plan.md` | Increment-specific scope |
| `project-charter.md` | Formal project authorization |
| `prd-feature-name.md` | Product requirements document |
| `00-system-name.md` | C4 system context (Level 1) |
| `00-01-container-name.md` | C4 container (Level 2) |
| `00-01-01-component-name.md` | C4 component (Level 3) |

## Key Documentation

- `AGENTS.md` — Primary instructions for AI assistants; also serves as the meta-repo's main reference
- `WORKFLOW.md` — Detailed workflow guide for creating, working in, and completing specs
- `docs/THREE_TIER_MEMORY.md` — How the org/project/repo/scratch memory system works
- `docs/FRONTMATTER_STANDARDS.md` — YAML front matter conventions for specs and plans

## Related Modules

| Module | Relationship |
|--------|-------------|
| [spec-driven-development](../spec-driven-development/) | Single-repo spec workflow. Use SDD *within* individual repos; use meta-repo to coordinate *across* repos. |
| [scratch-management-utilities](../scratch-management-utilities/) | Scratch memory tooling. The meta-repo's `context/scratch/` directories follow the same patterns. |

## Platform Support

| Platform | Bootstrap Script | Status |
|----------|-----------------|--------|
| macOS / Linux | `scripts/bootstrap.sh` | Supported |
| Windows | `scripts/Bootstrap.ps1` | Supported |
