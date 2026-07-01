# /push-to-jira

Create JIRA issues from specs or slice maps. Auto-detects standalone spec vs. decomposed slice map.

## Usage
/push-to-jira <target> --epic <EPIC-KEY> [--dry-run] [--force]

## Behavior

### Detection
- If `specs/planning/<target>-slices/<target>-slices.spec.md` exists → slice map mode
- Else if `specs/*/<target>/<target>.spec.md` exists → standalone spec mode
- Else halt with error

### Validation
- Verify parent epic exists via JIRA REST API
- Verify parent is type Epic
- Halt if validation fails

### Standalone Spec Mode
1. Create a Story issue from spec title, ACs, and description
2. Set `jira:` key in spec frontmatter with the created issue key
3. Create remote link back to spec in the repository

### Slice Map Mode
1. Create a Phase Story for the overall phase
2. Create Sub-Tasks for each slice
3. Set `jira_story:` in slice map frontmatter
4. Add `**Jira**: <KEY>` line per slice section
5. Skip slices that already have a Jira key (unless `--force`)

### API Calls
- `POST /rest/api/3/issue` — create issues
- `POST /rest/api/3/issue/<KEY>/remotelink` — link back to spec

## Reads
- `specs/planning/<target>-slices/<target>-slices.spec.md`
- `specs/*/<target>/<target>.spec.md`
- `.env.acli.local`

## Writes
- Spec frontmatter: `jira:` key
- Slice map frontmatter: `jira_story:`
- Slice sections: `**Jira**: <KEY>` lines
- JIRA issues (external)

## Notes
- Skip if `jira:` exists and no `--force`
