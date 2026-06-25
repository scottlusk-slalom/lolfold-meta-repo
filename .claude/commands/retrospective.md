# /retrospective

Analyze scratch memory, git changes, friction logs, and PR feedback to surface insights and promote context.

## Usage
/retrospective [<spec-id>] [--phase <name>] [--since <date>] [--dry-run]

Default `--since`: 30 days ago.

## Behavior

1. **Gather Sources** (skip missing gracefully):
   - `specs/*/<spec-id>/context/scratch/` — notes, decisions, friction logs
   - `project/project-repositories.yaml` — identify repos to scan
   - `_working/friction-log.md` per repo
   - PR review comments via `gh pr list --state merged`

2. **Analyze**:
   - Identify recurring friction patterns
   - Extract reusable techniques or patterns
   - Surface unresolved questions
   - Note what worked well vs. poorly

3. **Propose Promotions** (all require user approval):
   - Playbook entries → `project/ai-sdlc-playbook.md`
   - Patterns → `architecture/patterns/`
   - ADRs → `architecture/adr/`
   - Context updates → `architecture/context-index.md`

4. Execute approved promotions only.

## Reads
- `specs/*/<spec-id>/context/scratch/`
- `project/project-repositories.yaml`
- `_working/friction-log.md`
- Merged PR comments via `gh`

## Writes
- `project/ai-sdlc-playbook.md`
- Promoted files in `architecture/`

## Notes
- Never halts — skips missing sources gracefully
- All promotion actions require user approval before execution
