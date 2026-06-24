# Approved Patterns

## Spec Lifecycle

```
generate-spec → approve-spec → execute-spec → PR creation → archive-spec
  (specified)    (planned)      (executed)     (submitted)   (archived)
```

## Implementation Pattern: RED/GREEN/Refactor

1. **RED** — Write failing tests that encode the spec's success criteria
2. **GREEN** — Write minimal code to make tests pass
3. **Refactor** — Clean up while keeping tests green

## Isolation Pattern: Git Worktrees

Each spec execution creates isolated worktrees to prevent cross-contamination between concurrent specs. Worktrees are cleaned up on archive.

## Context Curation Pattern

Scratch memory is volatile and spec-scoped. On archive, valuable context is promoted upward:
- Spec-level `context/` — findings relevant to this spec's record
- Project-level (`architecture/`, `project/`) — cross-cutting decisions
- Org-level (`org/`) — patterns validated across multiple projects
