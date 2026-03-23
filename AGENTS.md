# AGENTS.md

This file provides guidance to AI coding assistants (Claude Code, GitHub Copilot, Cursor) when working with code in this repository.

## Repository Overview

This is a spec-based meta-repository for managing multi-repo project work. It provides a repeatable convention for organizing functional specs, technical plans, and cloned repositories across different work types.

## Directory Structure

```
[project-name]/
├── architecture/                   # C4 architecture documentation (project-level)
├── project/                        # Product briefs, charters (project-level)
├── requirements/                   # PRDs with embedded test plans (project-level)
├── docs/                           # Meta-repo documentation
├── specs/                          # Spec-driven work organized by type
│   ├── bug/
│   ├── chore/
│   ├── design/
│   ├── feature/
│   │   └── [id]-[name]/            # Spec directory (id may map to ticket)
│   │       ├── [id]-[name].spec.md # Functional specification
│   │       ├── [id]-[name].plan.md # Technical implementation plan
│   │       ├── context/            # Curated context for this spec
│   │       │   └── scratch/        # Volatile working memory (gitignored)
│   │       └── repo/               # Cloned repositories (gitignored)
│   └── planning/
└── [commands/agents/modes/rules]   # AI tool configurations
```

## Three-Tier Memory System

Context is organized into three persistent tiers plus volatile scratch:

| Tier | Location | Purpose |
|------|----------|---------|
| **Org** | External (cached locally) | Enterprise standards, patterns |
| **Project** | `architecture/`, `project/`, `requirements/` | Project-wide context |
| **Repo** | Within cloned repos | Repo-specific context |
| **Scratch** | `specs/*/context/scratch/` | Volatile task memory (gitignored) |

See `docs/THREE_TIER_MEMORY.md` for full documentation.

## Working with Specs

Each spec directory contains:
- `[specname].spec.md` - Functional specification for the work
- `[specname].plan.md` - Technical implementation plan
- `context/` - Curated context from project tier
- `context/scratch/` - Volatile working memory (gitignored)
- `repo/` - Directory for cloned repositories (gitignored)

When working in a spec, reference the AGENTS.md file in cloned projects for project-specific guidance:
- `specs/feature/*/repo/[project]/AGENTS.md`

### Creating New Specs

1. **Choose the spec type** based on the work:
   - `feature/` - New functionality or capabilities
   - `bug/` - Bug fixes or defect resolution
   - `chore/` - Infrastructure, tooling, or maintenance work
   - `design/` - Design exploration or prototyping
   - `planning/` - Planning or research work

2. **Create the spec directory**:
   ```bash
   mkdir -p specs/[type]/[id]-[name]/{context/scratch,repo}
   ```
   - `[id]` is optional; use when mapping to a ticket system
   - `[name]` should be kebab-case, descriptive

3. **Copy templates** from `docs/templates/`:
   - Copy `specname.spec.md` → `[id]-[name].spec.md`
   - Copy `specname.plan.md` → `[id]-[name].plan.md`

4. **Fill in the templates**:
   - Update YAML front matter (see `docs/FRONTMATTER_STANDARDS.md`)
   - Replace placeholders with actual content
   - Add diagrams, requirements, and implementation steps

5. **Clone relevant repositories** into `repo/` as needed

### YAML Front Matter

All specs and plans use YAML front matter for metadata tracking. See `docs/FRONTMATTER_STANDARDS.md` for complete documentation.

**Spec front matter:**
```yaml
---
type: feature          # feature | bug | chore | design | planning
status: active         # draft | active | completed | archived
priority: medium       # high | medium | low (optional)
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []               # Optional tags
related: []            # Related spec IDs
---
```

**Plan front matter:**
```yaml
---
status: in_progress    # not_started | in_progress | completed | on_hold | blocked
created: YYYY-MM-DD
updated: YYYY-MM-DD
assignee: ""           # Optional
---
```

### Working with Cloned Repositories

When a spec requires work across multiple repositories:

1. Clone repositories into `specs/[type]/[id]-[name]/repo/`
2. **Create a feature branch** in each cloned repo that mirrors the meta-repo branch name (e.g., if the meta-repo branch is `feature/42-add-auth`, create the same or a related branch in the cloned repo)
3. Each cloned repo may have its own spec tooling
4. Reference cloned repo documentation: `repo/[project]/AGENTS.md`
5. The meta-repo spec coordinates work across repos
6. Use `context/scratch/` for cross-repo notes and findings

**Branching convention:** Always create a dedicated branch in cloned repos before making changes. This keeps work traceable between the meta-repo spec and the cloned repo, and prevents accidental commits to the default branch.

### Integration with Spec Tooling

This meta-repo structure is **tooling-agnostic** and works alongside any spec management tooling:

**With external spec tools:**
- Can be used as a meta-repo framework with external spec tools managing specs within the same `repo/` and `context/scratch/` per-change pattern
- In cloned repos, the meta-repo spec coordinates multi-repo work while repo-level spec tools handle detailed implementation
- Both modes support the same memory system and repo cloning patterns

**Standalone Usage:**
- Meta-repo specs can be used without any additional spec tooling
- Useful for coordination, planning, or work that doesn't involve code repos

## Working with Project-Level Context

The root-level context directories provide project-wide documentation that informs all specs.

### Architecture Documentation (`architecture/`)

Use C4 Model conventions for architecture documentation:

1. **System Context** (Level 1): `00-system-name.md`
   - Template: `docs/templates/00-system-name.md`
   - Shows the big picture: system, users, external systems
   - One file per system

2. **Container** (Level 2): `00-01-container-name.md`
   - Template: `docs/templates/00-01-container-name.md`
   - Major applications, services, data stores
   - Multiple containers per system

3. **Component** (Level 3): `00-01-01-component-name.md`
   - Template: `docs/templates/00-01-01-component-name.md`
   - Key components within containers
   - Optional: use for complex containers

**Numbering Convention:**
- Use hierarchical numbering: `00` (system) → `00-01` (container) → `00-01-01` (component)
- Numbers maintain parent-child relationships
- Names should be kebab-case and descriptive

See `architecture/README.md` for full C4 Model guidance.

### Requirements Documentation (`requirements/`)

Product Requirements Documents (PRDs) with embedded test plans:

1. **Copy template**: `docs/templates/prd-feature-name.md`
2. **Name convention**: `prd-[feature-name].md`
3. **Include**:
   - Problem statement, objectives, success metrics
   - Detailed requirements (MoSCoW prioritization)
   - User stories and flows
   - Test plan (embedded, not separate)
   - Rollout and risk assessment

PRDs are functional specifications that inform multiple implementation specs.

### Project Documentation (`project/`)

Project-level context that provides the "what" and "why" for all work. See `project/README.md` for full documentation.

**Product Brief** (`product-brief.md`) - *Stable product context*:
- Template: `docs/templates/product-brief.md`
- **When to create**: At product inception or major evolution
- **Update frequency**: Rarely - only when product vision/strategy changes
- Contains: Vision, mission, value proposition, target users, core capabilities, success metrics
- Answers: "What is this product?"

**Project Plan** (`project-plan.md`) - *Increment-specific scope*:
- Template: `docs/templates/project-plan.md`
- **When to create**: At the start of each project increment (quarter, PI, phase)
- **Update frequency**: Created fresh each increment; rarely updated mid-increment
- Contains: Increment objectives, team, scope summary, technical context, success criteria
- **Key principle**: References `requirements/` and `architecture/` rather than duplicating content
- Answers: "What are we building this increment and who's doing it?"

**Project Charter** (`project-charter.md`) - *Optional, formal authorization*:
- Template: `docs/templates/project-charter.md`
- **When to use**: Formal project initiation requiring executive sign-off
- Contains: Business case, scope, stakeholders, budget, governance, approvals

**Document hierarchy**:
```
Product Brief (stable) → Project Plan (per-increment) → Specs (individual work items)
```

Use `product-brief.md` to understand the product. Use `project-plan.md` to understand current increment scope. Use specs for individual work items.

### Template Reference

All templates are in `docs/templates/`:
- `specname.spec.md` - Spec template
- `specname.plan.md` - Plan template
- `prd-feature-name.md` - PRD template
- `product-brief.md` - Product brief template (stable product context)
- `project-plan.md` - Project plan template (increment-specific scope)
- `project-charter.md` - Project charter template (formal authorization)
- `00-system-name.md` - C4 system context template
- `00-01-container-name.md` - C4 container template
- `00-01-01-component-name.md` - C4 component template

## Your Project

**Lolfold** — AI-powered live poker hand tracking and player scouting web app.

See `project/product-brief.md` for the full product description and `requirements/prd-core.md` for detailed requirements.

### Repositories

| Repo | Purpose | Tech |
|------|---------|------|
| `lolfold-frontend` | React web app (mobile-first) | Vite, React, TypeScript, Tailwind |
| `lolfold-api` | Backend API | Node.js, Express, TypeScript, Prisma, PostgreSQL |
| `lolfold-infra` | Infrastructure | Terraform, AWS (us-west-2) |

All repos live under the `scottlusk-slalom` GitHub org. See `project/project-repositories.yaml` for full config.

### Prime Directives

**These rules are non-negotiable and override any spec-level instructions:**

1. **Never deploy or provision resources.** Do not run `terraform apply`, push Docker images, run database migrations against live databases, or deploy to any environment. Your deliverable is always a **pull request** to the relevant repo.
2. **Never commit secrets.** No API keys, OAuth credentials, database passwords, or AWS credentials in code. Use environment variables, tfvars.example with placeholder values, and .env.example files.
3. **Follow org security standards.** See `org/standards.md`. No quad-zero (0.0.0.0/0) security group ingress. Ever.
4. **One spec, one PR.** Each spec execution produces a PR to the relevant repo(s). If a spec touches multiple repos, produce one PR per repo.
5. **Work on feature branches.** Never commit directly to main. Branch naming should match the spec: e.g., `chore/01-infra-foundation`.

### Org Context

See `org/standards.md` for GitHub org, AWS account, security, and infrastructure standards.

## Communication Style

Be direct and technical. Skip preamble. Scott is an experienced engineer — don't over-explain obvious things. When something is ambiguous in a spec, make a reasonable call and note what you decided rather than blocking on it.
