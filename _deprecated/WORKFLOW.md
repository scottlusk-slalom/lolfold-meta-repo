# Meta-Repo Workflow Guide

This document describes how to use the meta-repo for day-to-day work: creating specs, working within them, and completing them.

## Creating a Spec

### Using AI Commands

The fastest way to create a spec is with the built-in commands:

- **Claude Code**: `/new-spec`
- **GitHub Copilot**: `/new-spec` prompt
- **Cursor**: Follow the spec creation guidance in the auto-applied rules

The command will ask for:
1. **Spec type** — feature, bug, chore, design, or planning
2. **Spec name** — kebab-case descriptive name (e.g., `user-authentication`)
3. **Optional ID** — ticket or issue ID (e.g., `42` or `PROJ-123`)

### Manual Creation

```bash
# Create the directory structure
mkdir -p specs/feature/42-user-auth/{context/scratch,repo}

# Copy templates
cp docs/templates/specname.spec.md specs/feature/42-user-auth/42-user-auth.spec.md
cp docs/templates/specname.plan.md specs/feature/42-user-auth/42-user-auth.plan.md
```

Then update the YAML front matter in both files with the current date, type, and status.

### What Gets Created

```
specs/feature/42-user-auth/
├── 42-user-auth.spec.md     # Functional specification (status: draft)
├── 42-user-auth.plan.md     # Technical plan (status: not_started)
├── context/
│   └── scratch/             # Volatile working memory (gitignored)
└── repo/                    # Cloned repositories (gitignored)
```

## Working Within a Spec

### 1. Clone Relevant Repositories

Use `/sync-repo` or clone manually into the spec's `repo/` directory:

```bash
cd specs/feature/42-user-auth/
git clone git@github.com:your-org/backend-api.git repo/backend-api
```

**Important**: Always create a feature branch in cloned repos that mirrors the meta-repo branch name:

```bash
cd repo/backend-api
git checkout -b feature/42-user-auth
```

The `/sync-repo` command handles this automatically.

### 2. Curate Context

Copy relevant project-level context into the spec's `context/` directory:

```bash
# Copy architecture docs relevant to this spec
cp architecture/patterns/auth-strategy.md context/auth-reference.md

# Extract relevant requirements
cp requirements/prd-user-management.md context/requirements-extract.md
```

This gives quick access without hunting through project-tier directories.

### 3. Use Scratch Memory

The `context/scratch/` directory is for volatile working notes. It's gitignored — use it freely.

**Recommended structure:**
```
scratch/
├── references/          # Copied docs, external resources
├── transcripts/         # Meeting notes, conversation logs
├── notes.md            # General working notes
├── decisions.md        # Decision log with rationale
└── research.md         # Active research findings
```

See `docs/THREE_TIER_MEMORY.md` for detailed scratch memory conventions.

### 4. Work Across Repos

The meta-repo coordinates work across multiple repositories:

- Write the spec and plan in the meta-repo
- Implement changes in cloned repos (each on a feature branch)
- Use `context/scratch/` for cross-repo notes and findings
- Commit changes within each cloned repo, not the meta-repo

### 5. Track Progress

Update the plan's YAML front matter and task checkboxes as you work:

```yaml
---
status: in_progress
updated: 2025-12-15
---
```

Use `/list-specs` to see all specs and their statuses.

## Completing a Spec

### 1. Analyze Scratch Memory

Use `/analyze-scratch` to review what's in scratch memory and git changes:

- Identify valuable insights worth preserving
- Find architecture decisions embedded in code changes
- Flag temporary notes for deletion

### 2. Promote Valuable Context

Move important findings to permanent tiers:

| Content Type | Promote To |
|--------------|------------|
| Architecture decisions | `architecture/adr/` |
| Cross-cutting patterns | `architecture/patterns/` |
| API contracts | `architecture/contracts/` |
| Reference materials | `project/references/` |
| Repo-specific docs | Within the cloned repo |

See `docs/THREE_TIER_MEMORY.md` for the complete memory promotion routine.

### 3. Archive the Spec

Use `/archive-spec` to cleanly close out a spec:

1. Verifies all plan tasks are complete
2. Runs memory promotion analysis
3. Cleans up scratch memory and cloned repos
4. Updates spec status to "archived"
5. Creates an archive summary
6. Commits the archival

## Customizing for Your Project

### AGENTS.md

Fill in the placeholder sections:
- **Your Project** — describe what the project is, key repos, tech stack, constraints
- **Communication Style** — set your preferred AI interaction style

### project/project-repositories.yaml

Add your repositories so `/sync-repo` and `/new-spec` can suggest them:

```yaml
repositories:
  my-backend:
    purpose: Backend API service
    git:
      organization: my-org
      repository: my-backend
      clone_url: https://github.com/my-org/my-backend.git
      default_branch: main
    context:
      primary: AGENTS.md
```

### Templates

Edit templates in `docs/templates/` to match your team's conventions. The YAML front matter schema should remain consistent (see `docs/FRONTMATTER_STANDARDS.md`), but section content can be customized.

### Commands and Prompts

The commands in `.claude/commands/`, `.github/prompts/`, and `.cursor/rules/` can be modified to fit your workflow. They reference relative paths within the meta-repo, so they work without modification in most cases.

## Tips

- **Start small** — create a spec, clone a repo, do the work. The workflow becomes natural quickly.
- **Use scratch liberally** — it's gitignored, so write freely. Promote what matters when done.
- **One spec, one concern** — keep specs focused. If scope grows, split into multiple specs.
- **Branch naming** — mirror the meta-repo branch name in cloned repos for traceability.
- **Context is key** — the more you put into `architecture/`, `project/`, and `requirements/`, the more useful AI assistants become.
