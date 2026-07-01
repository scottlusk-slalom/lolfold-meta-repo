# Legacy Reference Documentation

This directory contains distilled documentation from legacy systems being modernized.

## Structure

```
architecture/legacy/
├── README.md                 ← this file
├── clone.sh                  ← script to clone/pull legacy repos
├── repos/                    ← gitignored read-only clones
│   └── <legacy-app>/
├── service_inventory.md      ← endpoint/service catalog
├── integration_map.md        ← system integration diagram
├── dependency-graph.yaml     ← component dependency tracking
├── data_model.md             ← database schema documentation
└── <system-name>.md          ← per-system distilled docs
```

## Workflow

1. Add repo entry to `clone.sh`
2. Run `./architecture/legacy/clone.sh` to clone/pull
3. Distill relevant information into `*.md` files alongside this README
4. Register new docs in `architecture/context-index.md`

## Repositories

| Directory | Source | Last Pulled |
|-----------|--------|-------------|
| (none yet — populate per engagement) | | |

## Clone and Pull

```bash
./architecture/legacy/clone.sh
```

If authentication is required, configure a credential helper:
```bash
git config --global credential.helper store
```

## Staleness Warning

Clones can become stale. Check freshness:
```bash
git -C architecture/legacy/repos/<name> fetch --dry-run
```

If output appears, the clone is behind remote.

## AI Usage Guidance

- These docs describe the **current state** (AS-IS) of legacy systems
- They are **read-only reference** — never modify source repos from here
- Do NOT confuse with target-state docs in `architecture/patterns/` or `architecture/contracts/`
- Treat claims as potentially stale — verify against source if critical
