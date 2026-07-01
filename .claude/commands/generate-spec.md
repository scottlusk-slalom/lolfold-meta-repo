# /generate-spec

Generate a functional spec and technical plan for a unit of work.

## Usage
/generate-spec <spec-id> "<brief description>" --type <feature|bug|chore|design|planning> [--scaffold-only] [--skip-curator] [--skip-analyzer] [--dry-run]

## Behavior

1. **Scaffold** the spec directory at `specs/<type>/<spec-id>/`:
   - `<spec-id>.spec.md` (status: specified)
   - `<spec-id>.plan.md` (status: not_started)
   - `status.md`
   - `context/CONTEXT.md`
   - `context/decisions.md`

2. If `--scaffold-only`, stop here.

3. **Requirements** (brief mode): Invoke `requirements-author` agent to produce ≥3 `REQ-N:` entries in `context/requirements.md`. Halt if brief is empty.

4. **Context Curation** (unless `--skip-curator`): Invoke `.claude/agents/context-curator.md` to select and stage reference docs into `context/`.

5. **Legacy Analysis** (unless `--skip-analyzer`): If legacy source exists, invoke `.claude/agents/legacy-analyzer.md` to produce `context/*-analysis.md`.

6. **Spec Writing**: Invoke `.claude/agents/spec-writer.md` to produce the final spec.

## Halt Conditions
- `⚠️ DESIGN DECISION REQUIRED` marker in analysis output
- `### UNRESOLVED:` entries without resolution
- Brief text is empty (requirements mode)

## Reads
- `architecture/context-index.md`
- `specs/*/<spec-id>/context/requirements.md`
- `docs/templates/specname.spec.md`
- `docs/templates/specname.plan.md`

## Writes
- `specs/<type>/<spec-id>/<spec-id>.spec.md` (status: specified)
- `specs/<type>/<spec-id>/<spec-id>.plan.md` (status: not_started)
- `specs/<type>/<spec-id>/status.md`
- `specs/<type>/<spec-id>/context/CONTEXT.md`
- `specs/<type>/<spec-id>/context/*-analysis.md`
- `specs/<type>/<spec-id>/context/decisions.md`

## Delegates To
- `requirements-author` agent (brief mode)
- `.claude/agents/context-curator.md`
- `.claude/agents/legacy-analyzer.md`
- `.claude/agents/spec-writer.md`
