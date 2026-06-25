# /sync-jira

Post spec repo URLs as remote links on JIRA stories, write gate status as comment, and optionally transition workflow status.

## Usage
/sync-jira [<spec-path>] [--transition <status>]

If no path given, syncs all specs that have a `jira:` frontmatter key.

## Behavior

1. **Load credentials** from `.env.acli.local` — halt if missing

2. **Find specs** to sync:
   - If path given: sync that spec only
   - Else: scan `specs/**/*.spec.md` for those with `jira:` frontmatter

3. **Per spec** (non-fatal — continue on errors):
   - Build spec link URL from `git remote get-url origin` + branch + spec path
   - POST remote link to JIRA issue via `/rest/api/3/issue/<KEY>/remotelink`
   - Read gate status from `project/gate-status.yaml`
   - POST comment with current gate status
   - If `--transition`: POST workflow transition

4. **Report** summary: synced / failed / skipped counts

## Reads
- `specs/**/*.spec.md`
- `.env.acli.local`
- `project/gate-status.yaml`

## Writes
- JIRA remote links (external)
- JIRA comments (external)
- JIRA transitions (external, if `--transition`)
- Spec frontmatter NOT modified

## Notes
- All per-story operations are non-fatal — continue on errors
- Reports synced/failed/skipped summary at end
