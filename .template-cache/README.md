# .template-cache/

Stores upstream snapshots of `merge[]` files (e.g. `AGENTS.md`) at each synced
template version. Used by `scripts/update-template.sh` as the three-way merge base.

## Structure

```
.template-cache/
└── 1.0.0/
│   └── AGENTS.md        ← upstream AGENTS.md at template v1.0.0
└── 1.2.0/
    └── AGENTS.md        ← upstream AGENTS.md at template v1.2.0
```

## Why this exists

A correct three-way merge needs three inputs:
1. **Base** — what the file looked like in upstream *at the last sync*
2. **Ours** — what we've changed locally since then
3. **Theirs** — what upstream looks like now

Without the cache, the base falls back to `git HEAD`, which is the last *local commit*,
not the upstream state. If you edited `AGENTS.md` locally after the last sync, that
local edit bleeds into the base and causes false conflicts.

## Maintenance

- Entries are written automatically after each successful sync.
- Old version directories are left in place — they're cheap and provide an audit trail.
- This directory is listed under `project:` in `template-manifest.yaml` and is never
  overwritten by the sync.
- Safe to commit to git (files are small Markdown docs).
