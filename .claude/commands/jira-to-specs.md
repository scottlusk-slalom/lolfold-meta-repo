# /jira-to-specs

Fetch stories from a JIRA epic or JQL query, scaffold spec dirs pre-populated from JIRA data, clone relevant repos, and run discovery scans.

## Usage
/jira-to-specs <EPIC-KEY | JQL>

## Behavior

1. **Load credentials** from `.env.acli.local`:
   - `ATLASSIAN_JIRA_TOKEN`, `ATLASSIAN_JIRA_USER`, `ATLASSIAN_JIRA_BASE_URL`
   - Halt if missing

2. **Fetch issues** via JIRA REST API:
   - Epic mode: fetch all child issues
   - JQL mode: execute query

3. **Map types**: Story→feature, Bug→bug, Task/Sub-task→chore, Epic→planning

4. **For each issue**, scaffold spec directory:
   - Path: `specs/<type>/<STORY-KEY>-<slug>/`
   - Create: spec file (`status: specified`), plan file, discovery.md
   - Plan `status: blocked` if blocking questions exist, else `not_started`
   - Skip if directory already exists (idempotent)

5. **Score repos** from `project/project-repositories.yaml`:
   - Select top ≤3 repos with relevance score > 0
   - Shallow-clone to `specs/<type>/<STORY-KEY>-<slug>/repo/<repo-name>/`

6. **Register gates**: Call `/update-gate <STORY-KEY>-<slug> specified` per spec

## Reads
- `.env.acli.local`
- `project/project-repositories.yaml`
- JIRA REST API

## Writes
- `specs/<type>/<STORY-KEY>-<slug>/` (spec dirs)
- `project/gate-status.yaml` (via `/update-gate`)

## Delegates To
- `/update-gate`

## Notes
- Idempotent — skips already-existing directories
