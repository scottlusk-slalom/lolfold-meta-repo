# /contribute-upstream

Push local framework overrides and source registrations back to the upstream harness
template as a pull request. Operates inside the `.template-cache/` clone (whose origin
is the template repo). This is the sync-UP path — the inverse of `/update-template`.

Delegates execution to `scripts/contribute-upstream.sh`.

## Usage

```
/contribute-upstream [--dry-run] [--scope <type>] [--rationale <text>] [--fork]
```

## Flags

| Flag | Behavior |
|------|----------|
| `--dry-run` | Detect candidates and show PR preview; no remote operations |
| `--scope <type>` | Limit to: `framework` \| `source` \| `all` (default: `all`) |
| `--rationale <text>` | Explanation for reviewers (required for live run) |
| `--fork` | Force PR creation via fork (instead of direct branch push) |

## Examples

```bash
# Preview what would be contributed
/contribute-upstream --dry-run

# Contribute only framework overrides
/contribute-upstream --scope framework --rationale "Add retry logic to sync"

# Force fork-based PR
/contribute-upstream --fork --rationale "New ADR source registration"
```

## What Travels Upstream

Only two candidate types are ever contributed:

1. **Framework overrides** — files under `.template-overrides/` whose corresponding source
   file in the repo differs from (or is absent in) the upstream cache clone.
2. **Source registrations** — entries in `org/sources.local.yaml` whose `name` is not yet
   present in the upstream `org/sources.yaml`.

### Never Contributed

- Synced org content (golden-path, silver-path, crossplane schemas)
- Sync state
- Project paths (specs, repos, planning)
- The `.template-overrides/` directory itself (only the source files they protect)

## Behavior

### 1. Prerequisites Check
Verifies: git, python3, `template-manifest.yaml` exists with `upstream.repo` set,
`--rationale` provided (unless `--dry-run`).

### 2. Read Manifest
Parse `template-manifest.yaml` for `upstream.repo`, `upstream.pinned_at`, `template_version`.
Derive `INSTANCE_ID` from `git remote get-url origin`.

### 3. Resolve .template-cache/ Clone
Verify `.template-cache/` is a git clone (has `.git/` directory and an origin remote).
If not present → halt with instructions to run `/update-template` first.

### 4. Refresh + Unshallow the Cache
- `git fetch origin` to get latest upstream state
- If the cache is a shallow clone: `git fetch --unshallow` (required for clean branch push)
- Reset to upstream HEAD

This is the potentially slow step on first contribute (fetches full history).

### 5. Detect Framework Override Candidates
Walk `.template-overrides/` (skip README.md). For each override:
- If the source file doesn't exist in the instance repo → skip (orphan placeholder)
- If the file exists upstream and differs from instance → **modified** candidate
- If the file doesn't exist upstream → **new** candidate
- If the file exists upstream and matches instance → not a candidate (already upstream)

### 6. Detect Source Registration Candidates
If `org/sources.local.yaml` exists, compare `sources[].name` against the cache's
`org/sources.yaml`. Names present locally but absent upstream are candidates.

### 7. Candidate Gate
Zero candidates → "Nothing to contribute", exit 0.
`--dry-run` → print branch, PR title, body, candidate list, and stop.

### 8. Build Provenance Envelope + PR Body
Stamps: INSTANCE_ID, template_version, last_sync (pinned_at), scope, rationale, timestamp.
Constructs branch name: `contribute/<instance-id>/<timestamp>`.

### 9. Verify GitHub CLI Auth
`gh auth status` — halt if not authenticated.

### 10. Branch, Apply, Commit — Inside .template-cache/
- Create branch in the cache clone
- Copy override source files onto the matching upstream paths
- Append new source blocks into upstream `org/sources.yaml`
- Commit with full provenance in the message

**Key mechanic:** the instance's working tree is never touched. All mutations happen
in `.template-cache/` whose origin is the template repo.

### 11. Push + Open PR, with Fork Fallback
- Attempt direct push of the branch to upstream origin
- If push fails (no write access) or `--fork` is set: retry via `gh pr create --fork`
- `--fork` forces that path upfront

### 12. Labels (Best-Effort)
Adds labels `contribution`, `path:<dir>`, `source:<name>`. Failures are silent.

### 13. Record Contribution
Writes `.template-contribution.yaml` in the instance repo root (gitignored):
branch, PR URL, instance, scope, template_version, last_sync, timestamp, candidates.

Returns the cache clone to its default branch after completion.

## The Override-Contribution Invariant

The override layer IS the contribution surface:
1. Place file in `.template-overrides/<path>` (protects from update-template's rsync --delete)
2. Make changes to the actual file at `<path>`
3. Run `/contribute-upstream` to push it upstream as a PR

"Customize locally" and "contribute upstream" are one mechanism.

## Source Lifecycle

1. Register in `org/sources.local.yaml`
2. Run sync to prove it pulls correctly
3. `/contribute-upstream` delivers the definition to upstream `org/sources.yaml`
4. After merge, retire the local entry from `org/sources.local.yaml`

## Relationship to /update-template

| Direction | Command | Mechanism |
|-----------|---------|-----------|
| DOWN (template → instance) | `/update-template` | Shallow-clones upstream into `.template-cache/`, syncs framework/merge paths |
| UP (instance → template) | `/contribute-upstream` | Unshallows `.template-cache/`, branches, applies overrides, pushes PR |

Both operate on `.template-cache/`. `update-template` creates it (shallow); `contribute-upstream`
unshallows it on first use.

## Reads
- `template-manifest.yaml`
- `.template-overrides/` (candidate detection)
- `.template-cache/` working tree (upstream comparison)
- `org/sources.local.yaml` (if exists)

## Writes (instance repo)
- `.template-contribution.yaml` (audit trail, gitignored)

## Writes (upstream via .template-cache/)
- Branch + commit with override files and/or source registrations
- PR opened against upstream default branch

## Never Touches
- Instance working tree files (besides `.template-contribution.yaml`)
- Anything listed under `project[]` in `template-manifest.yaml`

## Delegates To
- `scripts/contribute-upstream.sh`
