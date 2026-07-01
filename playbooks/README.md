# Playbooks

Machine instructions for the Loop agent. These are NOT human how-to guides — see `docs/how-to/` for those.

## How Playbooks Work

1. Playbooks are declared in a repo's `_loop-config.yaml` under the `playbooks:` key
2. At execute time, `/multi-repo-loop` loads matching playbooks
3. Playbook instructions are injected into the execution loop agent's context during the execute phase
4. The agent follows the playbook's constraints alongside the spec

## Available Playbooks

| Playbook | Scenario |
|----------|----------|
| `e2e-tdd-playwright` | UI specs with browser tests |
| `tdd-backend` | Backend API feature specs |
| `datastore-schema-modeling` | Data layer / schema specs |
| `copy-page-with-code` | UI page replication from source code |
| `cross-repo-parity-acceptance` | Behavioral parity ACs across repos |
| `visual-reference-discovery` | Visual pattern capture before TDD |

## Naming Convention

`<technique>-<tool-or-scope>.md`

Examples: `e2e-tdd-playwright`, `tdd-backend`, `datastore-schema-modeling`

## Playbook Frontmatter Schema

```yaml
---
name: <playbook-name>           # Must match _loop-config.yaml entry (without .md)
applies_when:
  loop_config:                  # Match against _loop-config.yaml fields
    key: value
  spec_section: "## Section"    # Match if spec contains this heading
  spec_tags_any: [tag1, tag2]   # Match if spec has any of these tags
  files_touched_any: [pattern]  # Match if spec modifies matching files
skip_when:                      # Conditions that disable this playbook
  spec_tags_any: [skip-tag]
requires: [dependency-list]     # Required tools/services
injects_into: execute           # Phase where instructions apply
---
```

## Key Rule

Playbook filenames (without `.md`) must **exactly match** entries in `_loop-config.yaml` `playbooks:` list.

Example:
```yaml
# _loop-config.yaml
playbooks:
  - datastore-schema-modeling    # → loads playbooks/datastore-schema-modeling.md
  - tdd-backend                  # → loads playbooks/tdd-backend.md
```
