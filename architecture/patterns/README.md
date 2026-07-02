# Architecture Patterns

This directory is intentionally empty in the template. Add validated patterns as they emerge from engagement work.

## Convention

Each pattern file should follow this shape:

```markdown
# <Pattern Name>

## Problem
What recurring challenge does this pattern solve?

## Pattern
The solution approach.

## Rules & Gotchas
- Constraints and edge cases
- When NOT to use this pattern

## Canonical Reference
Link to the spec or PR where this was first validated.
```

## How to Add

1. Identify a pattern validated across ≥1 spec (via `/retrospective`)
2. Write the pattern file: `architecture/patterns/<name>.md`
3. Register in `architecture/context-index.md`

## Distinction from `org/`

- `org/` — platform-wide requirements (apply to ALL repos)
- `architecture/patterns/` — project-specific patterns (apply to THIS project)

Platform-wide requirements belong in the org tier. Project patterns go here.
