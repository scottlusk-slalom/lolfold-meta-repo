# Project Context

This directory contains functional project information that provides broader context for the work being done.

## Core Documents

### Product Brief (`product-brief.md`)

**Purpose**: Stable, functional description of *what* the product is and *why* it matters.

**When to use**:
- Starting a new product or major product evolution
- Onboarding new team members who need product context
- Making strategic decisions about product direction

**Update frequency**: Rarely. Only when the product itself fundamentally changes.

**Key sections**:
- Vision & Mission
- Value Proposition
- Target Users
- Core Capabilities
- Success Metrics

**Template**: `../docs/templates/product-brief.md`

---

### Project Plan (`project-plan.md`)

**Purpose**: Increment-specific document capturing scope and context for a bounded period of work (quarter, PI, project phase).

**When to use**:
- Kicking off a new project increment or planning cycle
- Quarterly/PI planning sessions
- Communicating planned scope to stakeholders

**Update frequency**: Created at increment start, referenced throughout, rarely updated mid-increment.

**Key sections**:
- Increment Overview & Objectives
- Team & Roles
- Scope Summary (references `requirements/` for details)
- Technical Context (references `architecture/` for details)
- Success Criteria

**Template**: `../docs/templates/project-plan.md`

---

### Project Charter (`project-charter.md`) - Optional

**Purpose**: Formal project authorization document with approvals, budget, and governance.

**When to use**:
- Formal project initiation requiring executive sign-off
- Projects with significant budget or resource commitments
- When organizational process requires formal chartering

**Template**: `../docs/templates/project-charter.md`

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| `project-repositories.yaml` | List of relevant code repositories for this project |
| `roadmap.md` | (Optional) High-level timeline and milestones |
| `stakeholder-map.md` | (Optional) Key people and their interests |

## File Structure

```
project/
├── README.md                 # This file
├── product-brief.md          # Product vision and goals (stable)
├── project-plan.md           # Current increment scope (per-increment)
├── project-charter.md        # Formal project definition (optional)
├── project-repositories.yaml # List of relevant code repositories
└── [additional-context].md   # Other project context as needed
```

## Document Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     PRODUCT BRIEF                           │
│            (Stable product context - changes rarely)        │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ informs
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     PROJECT PLAN                            │
│         (Increment scope - created at each kickoff)         │
│                                                             │
│   References:                                               │
│   ├── requirements/*.md  (detailed PRDs)                    │
│   └── architecture/*     (technical decisions)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ breaks down into
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       SPECS                                 │
│              (Individual work items in specs/)              │
└─────────────────────────────────────────────────────────────┘
```

## Key Principles

### Product Brief is the "What"
- Describes the product independent of any specific project
- Should be readable by someone unfamiliar with current work
- Changes only when the product vision or strategy shifts

### Project Plan is the "When & Who"
- Scoped to a specific time period (quarter, PI, phase)
- Captures team, stakeholders, and intended scope
- References other documents rather than duplicating content
- Created fresh for each increment; old plans become historical record

### Source of Truth Hierarchy
- **Requirements details** → `requirements/prd-*.md`
- **Technical decisions** → `architecture/` and `architecture/adr/`
- **Individual work items** → `specs/`
- **Project plan** summarizes and references these, doesn't replace them

## Relationship to Other Context

| Context Type | Location | Purpose |
|--------------|----------|---------|
| Architecture | `../architecture/` | Systems and technical structure |
| Project | This directory | Product vision, increment scope |
| Requirements | `../requirements/` | Detailed PRDs and feature specs |
| Specs | `../specs/` | Individual work items with plans |

## See Also

- `../docs/THREE_TIER_MEMORY.md` - Memory system documentation
- `../docs/templates/` - Templates for all document types
- `../architecture/` - Technical architecture context
- `../requirements/` - PRDs and functional requirements
