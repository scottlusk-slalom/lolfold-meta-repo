# Three-Tier Memory System

Context hierarchy and loading/promotion rules for AI agents and human authors.

## Tier Table

| Tier | Location | Scope | Persistence |
|------|----------|-------|-------------|
| **Org** | `org/` | Enterprise-wide platform standards | Committed, 30-day refresh TTL |
| **Project** | `architecture/`, `project/`, `requirements/` | Project-wide decisions and context | Committed |
| **Repo** | `repos/<name>/` | Repo-specific implementation context | In cloned repos |
| **Scratch** | `specs/*/context/scratch/` | Volatile task-specific working memory | Gitignored |

## Context Priority Order

Narrower scope wins:
```
spec-level > repo-level > project-level > org-level
```

When context conflicts, the most specific tier takes precedence.

## CONTEXT.md Manifest Pattern

Each spec's `context/CONTEXT.md` is a manifest of selected references:
- Reference documents BY PATH only
- NEVER copy content across tiers
- Log selection rationale (why included, why excluded)

## Loading Order (starting a spec)

1. Load `architecture/context-index.md` (or `architecture/README.md` if absent)
2. Load spec-specific `context/CONTEXT.md` and its referenced docs
3. Load repo-level context (`repos/<name>/AGENTS.md`)
4. Load org-level requirements if infrastructure work (see `org/` directory)

## Memory Promotion Decision Table

After spec completion (`/finalize-spec` → `/retrospective`):

| Content Type | Promote To | Condition |
|-------------|-----------|-----------|
| Architectural decisions | `architecture/adr/` | Decision is durable and project-wide |
| Reusable patterns | `architecture/patterns/` | Pattern validated across ≥1 spec |
| API contracts | `architecture/contracts/` | Contract consumed by other repos |
| Repo-specific learnings | Cloned repo docs | Only relevant to that repo |
| Everything else | **Delete** | Not durable enough to promote |

**Rules:**
- Promotion requires user confirmation
- Never copy file body between tiers — reference by path
- If unsure, delete rather than promote

## Scratch Conventions

Files in `specs/*/context/scratch/`:
- `notes.md` — working notes, observations
- `decisions.md` — in-progress decision log
- `research.md` — research findings
- `references/` — temporary reference material
- `transcripts/` — conversation logs

**Rules:**
- Gitignored — never committed
- Do NOT put final docs here
- Do NOT duplicate content from higher tiers
- Cleaned up by `/finalize-spec`

## Org Tier

- Managed via `org/cache.yaml`
- 30-day refresh TTL (configurable via `stale_after_days`)
- Source tracked in `org/cache.yaml` `sources[]`
- Committed to version control (unlike scratch)
- Synced manually per engagement
