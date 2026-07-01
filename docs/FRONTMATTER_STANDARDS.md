# Frontmatter Standards

YAML front matter conventions for spec, plan, and slice-map files. Scripts and the loop commands validate against these schemas.

## Spec Front Matter

```yaml
---
type: feature              # feature | bug | chore | design | planning
status: specified          # specified | planned | executed | submitted | archived
priority: medium           # high | medium | low (optional)
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []                   # optional
related: []                # related spec IDs (optional)
---
```

### Spec Status Lifecycle (exact enum)
```
specified → planned → executed → submitted → archived
```

- `specified` — spec authored, requirements defined
- `planned` — approved and ready for execution
- `executed` — implementation complete, tests passing
- `submitted` — PR(s) opened for review
- `archived` — work merged and spec closed out

## Plan Front Matter

```yaml
---
status: not_started        # not_started | approved | in_progress | completed | on_hold | blocked
created: YYYY-MM-DD
updated: YYYY-MM-DD
estimated_effort: medium   # low | medium | high
assignee: ""               # optional
---
```

### Plan Status Enum
```
not_started | approved | in_progress | completed | on_hold | blocked
```

- `not_started` — scaffolded, not yet reviewed
- `approved` — reviewed and approved for work
- `in_progress` — actively being implemented
- `completed` — all work done
- `on_hold` — paused, will resume
- `blocked` — cannot proceed (see blocking questions)

### `estimated_effort` Rule
Determined by dependency depth + validation complexity — never human-time durations:
- `low` — single module, no cross-service deps, straightforward validation
- `medium` — 2 modules or moderate validation complexity
- `high` — cross-service, complex validation, or multiple integration points

## Harness-Managed Fields

These fields are written by specific commands and should not be manually edited:

| Field | Owner Command | Purpose |
|-------|--------------|---------|
| `jira` | `/push-to-jira` | Linked Jira issue key |
| `jira_story` | `/push-to-jira` | Phase story key (slice maps) |
| `slice` | `/decompose-phase` | Slice identifier within a phase |
| `phase` | `/decompose-phase` | Parent phase name |
| `initiative` | `/generate-spec` | Parent initiative ID |
| `repos` | `/multi-repo-loop` | Target repos for execution |
| `slices` | `/decompose-phase` | Slice count (slice maps) |
| `parallel_steps` | `/decompose-phase` | Step count (slice maps) |
| `generated` | various | ISO date of generation |

## Slice-Map Spec Front Matter

Slice maps carry a subset of fields:

```yaml
---
type: planning
status: draft              # draft | approved
phase: <phase-name>
jira_story: ""             # set by /push-to-jira
generated: YYYY-MM-DD
slices: <count>
parallel_steps: <count>
---
```

### Slice Map Status
```
draft | approved
```

Set by `/decompose-phase` (`draft` on sizing violations, `approved` on pass) and `/approve --stage slices`.

## Key Distinctions
- **Spec status** is lifecycle-focused (where is this work in the pipeline?)
- **Plan status** is implementation-focused (what is the state of the work itself?)
- Spec status is consumed by `validate-loop-config.sh` and `/multi-repo-loop`
