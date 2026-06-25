# /onboard-legacy-repo

Clone a legacy repo, extract reference docs, run service weight analysis, and update the dependency graph.

## Usage
/onboard-legacy-repo

Identifies the repo from user input or `architecture/legacy/README.md`.

## Behavior

1. **Identify** the legacy repo to onboard (prompt user if ambiguous)

2. **Clone** to `architecture/legacy/repos/<dir>/` (gitignored)

3. **Extract** reference documentation:
   - Endpoint inventory (mandatory if >3 endpoints)
   - Weight table with columns: endpoint, method, complexity, disposition
   - Disposition values: `port | keep-as-is | deprecate | blocked | unknown`

4. **Write** distilled doc: `architecture/legacy/<name>.md`
   - Endpoints table
   - Service weight table
   - Integration points

5. **Update** `architecture/legacy/README.md` with repo entry

6. **Update** `architecture/legacy/clone.sh` with clone command

7. **Update** `architecture/context-index.md` with new doc reference

8. **Update** `architecture/legacy/dependency-graph.yaml`:
   ```yaml
   schema_version: "1.0"
   components:
     <name>:
       type: <service|library|database>
       description: <text>
       artifact: <repo-url>
       consumed_by: []
       consumes: []
       replacement_status: not_started
       replacing_repo: null
       replacing_specs: []
       decommission_blocked_by: []
   ```

## Reads
- `architecture/legacy/README.md`
- `project/product-brief.md`
- `planning/blockers.md`
- Legacy repo source files

## Writes
- `architecture/legacy/repos/<dir>/` (gitignored clone)
- `architecture/legacy/<name>.md`
- `architecture/legacy/README.md`
- `architecture/legacy/clone.sh`
- `architecture/context-index.md`
- `architecture/legacy/dependency-graph.yaml`

## Key Rules
- Only `port` disposition items are work to plan
- Weight table mandatory for repos with >3 endpoints
- `dependency-graph.yaml` schema must include `schema_version: "1.0"`
