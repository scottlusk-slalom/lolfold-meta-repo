# YAML Front Matter Standards

This document defines the YAML front matter conventions for spec and plan files in the meta-repository.

## Spec Files ([specname].spec.md)

Spec files use front matter to track high-level metadata about the work item.

```yaml
---
type: feature          # feature | bug | chore | design | planning
status: active         # draft | active | completed | archived
priority: medium       # high | medium | low (optional)
created: 2025-12-11    # YYYY-MM-DD
updated: 2025-12-11    # YYYY-MM-DD
tags: []               # Optional array of tags
related: []            # Optional array of related spec IDs (e.g., ["01-meta-repo-setup"])
---
```

### Field Definitions

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `type` | Yes | `feature`, `bug`, `chore`, `design`, `planning` | Category of work, matches directory structure |
| `status` | Yes | `draft`, `active`, `completed`, `archived` | Lifecycle status of the spec |
| `priority` | No | `high`, `medium`, `low` | Relative priority for planning |
| `created` | Yes | `YYYY-MM-DD` | Date the spec was created |
| `updated` | Yes | `YYYY-MM-DD` | Date of last update |
| `tags` | No | Array of strings | Arbitrary tags for categorization |
| `related` | No | Array of spec IDs | Links to related specs |

### Status Values

- **draft** - Spec is being written, not yet ready for implementation
- **active** - Spec is approved and ready for/undergoing implementation
- **completed** - Implementation is complete and validated
- **archived** - Spec is no longer active (superseded, cancelled, or old)

## Plan Files ([specname].plan.md)

Plan files use front matter to track implementation status and logistics.

```yaml
---
status: in_progress    # not_started | in_progress | completed | on_hold | blocked
created: 2025-12-11    # YYYY-MM-DD
updated: 2025-12-11    # YYYY-MM-DD
assignee: ""           # Optional: person or team responsible
estimated_effort: ""   # Optional: rough size estimate
blocker: ""            # Optional: description if status is blocked
---
```

### Field Definitions

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `status` | Yes | `not_started`, `in_progress`, `completed`, `on_hold`, `blocked` | Current implementation status |
| `created` | Yes | `YYYY-MM-DD` | Date the plan was created |
| `updated` | Yes | `YYYY-MM-DD` | Date of last update |
| `assignee` | No | String | Person or team implementing this plan |
| `estimated_effort` | No | String | Rough size estimate (e.g., "2-3 days", "1 week") |
| `blocker` | No | String | Brief description of blocker (if status is `blocked`) |

### Status Values

- **not_started** - Implementation has not begun
- **in_progress** - Currently being worked on
- **completed** - Implementation finished and validated
- **on_hold** - Temporarily paused (not blocked, just deprioritized)
- **blocked** - Waiting on external dependency or decision

## Implementation Notes

1. **Date Format**: Always use ISO 8601 date format (`YYYY-MM-DD`)
2. **Status Tracking**: The plan status is implementation-focused, while spec status is lifecycle-focused
3. **Updates**: Update the `updated` field whenever the file content changes
4. **Optional Fields**: Leave optional fields as empty strings or omit them entirely
5. **Array Format**: Use YAML array syntax for `tags` and `related` fields: `["tag1", "tag2"]` or multi-line format

## Examples

### Feature Spec Example

```yaml
---
type: feature
status: active
priority: high
created: 2025-12-10
updated: 2025-12-11
tags: ["authentication", "security"]
related: ["02-user-management"]
---
```

### Bug Spec Example

```yaml
---
type: bug
status: active
priority: high
created: 2025-12-11
updated: 2025-12-11
tags: ["hotfix", "production"]
---
```

### Plan Example (In Progress)

```yaml
---
status: in_progress
created: 2025-12-10
updated: 2025-12-11
assignee: "Engineering Team"
estimated_effort: "3-4 days"
---
```

### Plan Example (Blocked)

```yaml
---
status: blocked
created: 2025-12-08
updated: 2025-12-11
blocker: "Waiting on API design approval from architecture team"
---
```

## AI Assistant Guidance

When AI assistants create or update specs and plans:

1. Always include front matter with required fields
2. Set `created` to the current date when creating new files
3. Update `updated` field to the current date when modifying files
4. Use appropriate status values based on the current state
5. Infer `type` from the spec directory location (e.g., `specs/feature/` → `type: feature`)
