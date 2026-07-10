# /update-gate

Record a spec lifecycle gate transition. This is the ONLY command that writes to `project/gate-status.yaml`.

## Usage
/update-gate <spec-id> <status> [--evidence <url>] [--reason <text>] [--force]

## Status Enum (exact)
`specified | planned | executed | submitted | archived`

## Behavior

1. Read `project/gate-status.yaml` (create with `specs: {}` header and comment lines if missing)
2. Validate transition:
   - Must advance exactly one step forward: specified→planned→executed→submitted→archived
   - **New-entry auto-seed:** if no entry exists for `<spec-id>`, seed it at the spec's current frontmatter `status` (the real state — fall back to `specified` if unreadable), then apply the requested transition if it is exactly one step forward from that seed. This makes both `/approve` (`planned` on a fresh `specified` spec) and an orchestrator handoff (`executed` on a spec whose frontmatter already reads `planned`) succeed without `--force`. A request more than one step past the seed is still rejected unless `--force`.
   - Backward or skip transitions rejected (unless `--force`)
3. Write/update the entry:
   ```yaml
   # gate-status.yaml — lifecycle state of active specs under the top-level `specs:` key
   # Updated by /approve and /update-gate commands

   specs:
     <spec-id>:
       type: <feature|bug|...>   # from spec frontmatter
       status: <status>
       approved_at: <ISO-date>   # set when status → planned
       submitted_at: <ISO-date>  # set when status → submitted
       archived_at: <ISO-date>   # set when status → archived
       evidence: <url>           # if provided
       path: <spec dir path>     # e.g. specs/feature/foo
   ```
   Stamp the appropriate `*_at` field for the transition: `planned`→`approved_at`, `submitted`→`submitted_at`, `archived`→`archived_at`. Seed state `specified` gets no stamp. Set `type` from spec frontmatter when creating a new entry. Set `path` to the spec directory.
4. Update `specs/*/<spec-id>/status.md` with `gate:` and `pr:` fields if evidence provided.

**Note:** In the cloud model, gate writes are performed by the orchestrator on the `spec/<type>/<key>` spec branch (not `main`). The command's file operations are unchanged.

## Reads
- `project/gate-status.yaml`
- `specs/*/<spec-id>/status.md`

## Writes
- `project/gate-status.yaml`
- `specs/*/<spec-id>/status.md`
