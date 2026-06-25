# Org Tier — Platform Standards

Navigation hub for org-level context. This directory caches platform standards for AI agent consumption.

## Structure

```
org/
├── README.md                    ← this file
├── cache.yaml                   ← source tracking and refresh metadata
├── golden-path/                 ← platform requirements and validation rules
│   ├── requirements.md          ← distilled platform requirements
│   └── gp-rules.json           ← machine-checkable validation rules
└── sources/                     ← gitignored clones of upstream repos
    └── platform-handbook/       ← (cloned by sync-gp.sh)
```

## Which Platform?

[POPULATE PER ENGAGEMENT]

Describe your target platform here: deployment model, service mesh, observability stack, etc.

## Usage

- **Platform requirements**: `golden-path/requirements.md`
  - Human-readable distilled requirements
  - Loaded by agents for infrastructure/deployment specs

- **Validation rules**: `golden-path/gp-rules.json`
  - Machine-checkable rules executed by `scripts/validate-gp.sh`
  - Extend with project-specific rules as needed

## Refresh

Platform standards are cached with a staleness threshold:

```yaml
# org/cache.yaml
stale_after_days: 30
```

- Check staleness: `./scripts/sync-gp.sh --check-only`
- Full sync: `./scripts/sync-gp.sh`
- `AGENTS.md` instructs sessions to check at startup

Sources are cloned to `org/sources/` (gitignored) — only distilled docs are committed.
