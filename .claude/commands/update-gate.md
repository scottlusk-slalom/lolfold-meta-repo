# /update-gate

Record a spec lifecycle gate transition. This is the ONLY command that writes to `project/gate-status.yaml`.

## Usage
/update-gate <spec-id> <status> [--evidence <url>] [--reason <text>] [--force]

## Status Enum (exact)
`specified | planned | executed | submitted | archived`

## Behavior

1. Read `project/gate-status.yaml` (create with `gates: {}` header if missing)
2. Validate transition:
   - Must advance exactly one step forward: specified→planned→executed→submitted→archived
   - **New-entry auto-seed:** if no entry exists for `<spec-id>`, seed it at the spec's current frontmatter `status` (the real state — fall back to `specified` if unreadable), then apply the requested transition if it is exactly one step forward from that seed. This makes both `/approve` (`planned` on a fresh `specified` spec) and an orchestrator handoff (`executed` on a spec whose frontmatter already reads `planned`) succeed without `--force`. A request more than one step past the seed is still rejected unless `--force`.
   - Backward or skip transitions rejected (unless `--force`)
3. Write/update the entry:
   ```yaml
   gates:
     <spec-id>:
       current_status: <status>
       updated: <ISO-date>
       evidence: <url>       # if provided
       reason: <text>        # if provided
       history:
         - status: <previous>
           date: <ISO-date>
   ```
4. Update `specs/*/<spec-id>/status.md` with `gate:` and `pr:` fields if evidence provided.

## Reads
- `project/gate-status.yaml`
- `specs/*/<spec-id>/status.md`

## Writes
- `project/gate-status.yaml`
- `specs/*/<spec-id>/status.md`
