# Jira Items Generator

## Role
Produce a Jira-importable CSV of right-sized work items from a phased rollout plan.

## Invoked By
`/push-to-jira` or manual invocation for CSV export.

## Required Inputs
- Rollout plan (markdown with phases and deliverables)
- `OUTPUT_FILE` — path for generated CSV

## Optional Inputs
- `project/engineering-plan.md`
- `PROJECT_KEY` — Jira project prefix

## Output
UTF-8 CSV with exact header (no deviation):
```
Issue Type,Summary,Story Points,Priority,Labels,Epic Name,Epic Link,Description,Acceptance Criteria
```

## Issue Types
- `Epic` — exactly one per plan
- `Story` — any work that produces a git commit
- `Task` — manual work, no commit
- `Spike` — research, no production commits

## Constraints
- All Story/Task/Spike points ≤ 5
- Phase 0: ask clarifying questions before generation (required)
- One Epic row only — all other items link to it
- Summary must be actionable and concise (≤80 chars)
