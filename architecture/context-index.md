# Context Index

Maps task types to pre-distilled reference docs. Agents load this first to avoid hunting.

## Directory Convention

```
architecture/
├── context-index.md          ← this file (load first)
├── legacy/                   ← AS-IS: current state of legacy systems
│   ├── service_inventory.md
│   ├── integration_map.md
│   ├── data_model.md
│   └── repos/               ← gitignored read-only clones
├── patterns/                 ← TARGET: validated project patterns
├── adr/                      ← TARGET: architectural decision records
└── contracts/                ← TARGET: cross-repo API contracts
```

**Rule:** `architecture/legacy/` documents describe AS-IS state. All other `architecture/` documents describe TARGET state. Never confuse the two.

## Always Load

These documents are loaded for every spec regardless of type:

| Document | Purpose |
|----------|---------|
| `project/product-brief.md` | Product vision and context |
| `project/project-plan.md` | Current increment scope |
| `architecture/legacy/00-<system>.md` | System overview (if exists) |

## Load for Infrastructure/Deployment

| Document | Purpose |
|----------|---------|
| `org/golden-path/requirements.md` | Platform compliance requirements |

## Load by Task

| Task Type | Documents | Notes |
|-----------|-----------|-------|
| Datastore schema | [POPULATE PER PROJECT] | |
| Backend API | [POPULATE PER PROJECT] | |
| New repo setup | [POPULATE PER PROJECT] | |
| Helm/deployment | [POPULATE PER PROJECT] | |
| Secrets management | [POPULATE PER PROJECT] | |
| CI/CD pipeline | [POPULATE PER PROJECT] | |
| Legacy deep-dive | [POPULATE PER PROJECT] | |
| PRD authoring | [POPULATE PER PROJECT] | |

## Meta-Repo Operations

| Operation | Documents |
|-----------|-----------|
| Spec creation | `docs/FRONTMATTER_STANDARDS.md`, `docs/templates/specname.spec.md` |
| Repo onboarding | `docs/onboard-repo-runbook.md`, `docs/templates/repo-lifecycle.md` |
| Legacy onboarding | `architecture/legacy/README.md` |
| Memory system | `docs/THREE_TIER_MEMORY.md` |
| Workflow | `META-REPO-GUIDE.md`, `docs/modernization-workflow-v2.md` |

## Reference Doc Descriptions

### Patterns
| Document | Description |
|----------|-------------|
| (none yet — add as patterns are validated) | |

### Org Tier
| Document | Description |
|----------|-------------|
| `org/golden-path/requirements.md` | Platform compliance requirements |
| `org/golden-path/gp-rules.json` | Machine-checkable validation rules |
