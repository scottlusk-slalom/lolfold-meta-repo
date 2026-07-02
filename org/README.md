# Org Tier — Platform Standards

Navigation hub for org-level context. This directory caches platform standards for AI agent consumption.

## Structure

```
org/
├── README.md                    ← this file
├── cache.yaml                   ← source tracking and refresh metadata
└── sources/                     ← gitignored clones of upstream repos
```

## Which Platform?

[POPULATE PER ENGAGEMENT]

Describe your target platform here: deployment model, service mesh, observability stack, etc.

## Refresh

Platform standards are cached with a staleness threshold configured in `cache.yaml`.
Sources are cloned to `org/sources/` (gitignored) — only distilled docs are committed.
