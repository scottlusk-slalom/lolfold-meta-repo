# /update-template

Sync the latest framework files from the upstream harness template into this derived repo.
Governed by `template-manifest.yaml`. Delegates execution to `scripts/update-template.sh`.

## Usage

```
/update-template [--check-only] [--dry-run]
```

## Flags

| Flag | Behavior |
|------|----------|
| `--check-only` | Compare versions and diff framework paths; no writes, no manifest update |
| `--dry-run` | Full sync simulation — shows every file that would be written; no writes |

## Examples

```bash
# Check if an update is available (no changes)
/update-template --check-only

# Preview what would change without writing anything
/update-template --dry-run

# Run a full sync
/update-template
```

## Behavior

### 1. Prerequisites Check
Delegate to `scripts/update-template.sh`, which verifies:
- `git` is installed and the current directory is a git repo
- `rsync` is available
- `yq` or Python 3 is available (for YAML parsing)
- `template-manifest.yaml` exists in the repo root
- `upstream.repo` is set in `template-manifest.yaml` — **halt immediately** if blank or missing:
  ```
  ERROR: upstream.repo is not set in template-manifest.yaml.
  Open template-manifest.yaml and set:
    upstream:
      repo: /path/to/ae-harness-platform-poc   # local clone path OR git URL
  Then retry /update-template.
  ```

### 2. Read Manifest
Parse `template-manifest.yaml` for:
- `upstream.repo` — local path or git URL of the template source
- `template_version` / `upstream.pinned_at` — current local version
- `framework[]` — paths synced wholesale (overwritten)
- `merge[]` — paths merged, not overwritten
- `project[]` — paths never touched

### 3. Resolve Upstream
- If `upstream.repo` is a local path: use it directly
- If `upstream.repo` is a git URL: shallow-clone to a temp directory `/tmp/harness-template-sync-<timestamp>`; clean up on exit (even on error)
- If the path/URL is unreachable: print a clear error with the value that failed, then halt

### 4. Version Check
- Read `template_version` from the upstream `template-manifest.yaml`
- Compare to local `upstream.pinned_at`
- If equal: print `Already up to date (v<version>)` and exit 0

### 5. Override List
Before syncing, build the skip list from `.template-overrides/`:
- Walk `.template-overrides/` — each file path mirrors a framework path
- Any framework file with a matching override entry is skipped during sync
- Report all active overrides at the top of the output

### 6. Diff Report (always shown)
For every path in `framework[]`:
- If directory: list files that are added, removed, or modified vs upstream
- If file: show whether it has changed
Format:
```
  CHANGED  .claude/commands/scaffold-repo.md
  ADDED    .claude/commands/new-command.md
  REMOVED  .claude/commands/old-command.md
  OVERRIDE scripts/my-custom.sh  (skipped — .template-overrides/scripts/my-custom.sh)
  same     .gitignore
```

### 7. Sync Framework Paths (skipped in `--check-only` and `--dry-run`)
For each path in `framework[]` that is NOT in the override list:
- Directory: `rsync -a --delete <upstream>/<path>/ ./<path>/`
- File: `cp <upstream>/<path> ./<path>`
Track count of files updated.

### 8. Merge Base Resolution
For each path in `merge[]`, the three-way merge base is resolved in this order:
1. `.template-cache/<pinned_version>/<file>` — exact upstream state at the last sync (most accurate)
2. `git show HEAD:<file>` — last committed local version (fallback if no cache entry)
3. Local working copy — last resort

The cache entry is always preferred because it captures what upstream looked like *at pin time*, not what was locally committed. This avoids false conflicts caused by local edits made after the last sync.

### 9. Merge Review (skipped in `--check-only` and `--dry-run`)
For each path in `merge[]`:
- If upstream version differs from local: run `git merge-file` (three-way: local | git HEAD | upstream)
- If clean merge: mark ✓ clean
- If conflicts: leave conflict markers in place, mark ✗ conflict — do NOT abort
- Print all merge results grouped:
  ```
  Merge results:
    ✓  AGENTS.md  (merged cleanly)
    ✗  some-other.md  (conflicts — review required)
  ```

### 10. Populate Cache (skipped in `--check-only` and `--dry-run`)
After a successful sync, copy each upstream `merge[]` file into:
```
.template-cache/<upstream_version>/<merge_path>
```
This snapshot becomes the merge base for the *next* sync. Old version directories are left in place (cheap, useful for audit trail).

### 11. Update Manifest (skipped in `--check-only` and `--dry-run`)
- Set `upstream.pinned_at` in `template-manifest.yaml` to the upstream `template_version`

### 12. Final Report
Always print a summary block:
```
╭─────────────────────────────────────────────╮
│  Template Sync Report                        │
╰─────────────────────────────────────────────╯
  Mode:                dry-run / check-only / live
  From version:        v1.0.0
  To version:          v1.2.0
  Upstream:            /path/or/url

  Framework files:     12 changed, 2 added, 0 removed
  Overrides skipped:   1
  Merge files:         1 clean, 0 conflicted

  Status: ✓ Sync complete
     -or- ✓ No changes (already up to date)
     -or- ⚠ Conflicts found — review before committing
```

### 13. Commit Prompt (live mode only, after clean sync)
If sync completed with no conflicts:
```
Changes are staged. Ready to commit?

Suggested commit:
  git add -A && git commit -m "chore: sync harness template v1.0.0 → v1.2.0"

Run the commit now? [y/N]
```
If the user confirms, run the commit. If declined, remind:
```
Review changes with:  git diff
Commit when ready:    git add -A && git commit -m "chore: sync harness template v1.0.0 → v1.2.0"
```

If conflicts exist, skip the commit prompt and print instead:
```
⚠ Merge conflicts found. Resolve conflicts in the files listed above,
  then commit manually:
  git add -A && git commit -m "chore: sync harness template v1.0.0 → v1.2.0"
```

## Override System

Place files in `.template-overrides/` to protect them from being overwritten during sync.
The path inside `.template-overrides/` must mirror the framework path exactly.

**Example:** To prevent `.claude/commands/scaffold-repo.md` from being overwritten:
```
.template-overrides/
└── .claude/
    └── commands/
        └── scaffold-repo.md   # content ignored — presence alone triggers the skip
```

The `.template-overrides/` directory is listed under `project[]` in `template-manifest.yaml`
and is never touched by the sync.

## Reads
- `template-manifest.yaml`
- All paths under `framework[]` and `merge[]`
- `.template-overrides/` (override skip list)
- `.template-cache/<pinned_version>/` (merge base for `merge[]` files)

## Writes (live mode only)
- All paths under `framework[]` not in `.template-overrides/`
- All paths under `merge[]` (merged in place)
- `template-manifest.yaml` (`upstream.pinned_at`)
- `.template-cache/<new_version>/` (upstream snapshot of `merge[]` files)

## Never Touches
- Anything listed under `project[]` in `template-manifest.yaml`
- Any framework path with a matching file in `.template-overrides/`
- `.template-cache/` entries from prior versions (left as audit trail)

## Delegates To
- `scripts/update-template.sh`
