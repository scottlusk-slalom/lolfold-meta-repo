# /list-specs

Display all specs organized by type and status.

## Usage
/list-specs

## Behavior

1. Scan `specs/*/**/*.spec.md` for all spec files
2. Parse YAML frontmatter: `type`, `status`, `priority`, `created`, `tags`
3. Display grouped by status in lifecycle order:
   - specified → planned → executed → submitted → archived
4. Within each group, sort by priority (high → medium → low) then created date

## Output Format
```
## Specified (3)
| Spec | Type | Priority | Created | Tags |
|------|------|----------|---------|------|
| ...  | ...  | ...      | ...     | ...  |

## Planned (1)
...
```

## Notes
- Read-only — writes nothing
- Never halts — reports empty table if no specs found
- Skips files with invalid/missing frontmatter (warns inline)
