# Meta-Repository Spec Management Instructions

## Repository Overview

This is a spec-based meta-repository for managing multi-repo project work. It provides a repeatable convention for organizing functional specs, technical plans, and cloned repositories.

## Directory Structure

- `specs/` - Spec-driven work organized by type (bug, chore, design, feature, planning)
- Each spec contains: `.spec.md`, `.plan.md`, `context/`, `context/scratch/`, `repo/`
- `architecture/` - C4 architecture documentation (project-level)
- `requirements/` - PRDs with embedded test plans (project-level)
- `project/` - Product briefs and charters (project-level)
- `docs/templates/` - Reusable templates for specs and context

## Three-Tier Memory System

Context is organized into three persistent tiers plus volatile scratch:
1. **Org** - External (cached locally): Enterprise standards, patterns
2. **Project** - Root-level dirs: Project-wide context
3. **Repo** - Within cloned repos: Repo-specific context
4. **Scratch** - `specs/*/context/scratch/`: Volatile task memory (gitignored)

## Coding Guidelines

### When Creating New Specs

1. **Choose the appropriate type:**
   - `feature/` - New functionality or capabilities
   - `bug/` - Bug fixes or defect resolution
   - `chore/` - Infrastructure, tooling, or maintenance work
   - `design/` - Design exploration or prototyping
   - `planning/` - Planning or research work

2. **Use the naming convention:** `specs/{type}/{id}-{name}/`
   - `{id}` is optional; use when mapping to a ticket system
   - `{name}` should be kebab-case and descriptive

3. **Copy templates from** `docs/templates/`:
   - `specname.spec.md` → `{id}-{name}.spec.md`
   - `specname.plan.md` → `{id}-{name}.plan.md`

4. **Update YAML front matter:**
   - See `docs/FRONTMATTER_STANDARDS.md` for conventions
   - Set appropriate dates, status, type, and priority

### When Working Within a Spec

- Clone repositories into `spec-dir/repo/` (gitignored in meta-repo)
- **Create a feature branch** in each cloned repo that mirrors the meta-repo branch name before making changes
- Use `context/scratch/` for volatile working notes
- Reference cloned repo AGENTS.md: `spec-dir/repo/{project}/AGENTS.md`
- Commit changes within cloned repos, not the meta-repo — always on a feature branch, never the default branch

### Memory Promotion

When completing a spec:
- Analyze `context/scratch/` for valuable insights
- Review git changes for architectural decisions
- Promote to appropriate tiers:
  - Spec `context/` - Reference material for this spec
  - `architecture/`, `requirements/`, `project/` - Project-wide insights
- Delete temporary scratch notes

## Available Slash Commands

- `/new-spec` - Create new spec with templates
- `/list-specs` - Show all specs by type/status
- `/sync-repo` - Clone/update repos for a spec
- `/analyze-scratch` - Review scratch memory for promotion
- `/archive-spec` - Archive completed spec with cleanup

## Key Files

- `AGENTS.md` - Complete meta-repo guidance (always consult first)
- `docs/THREE_TIER_MEMORY.md` - Memory system details
- `docs/FRONTMATTER_STANDARDS.md` - Metadata conventions
