---
status: not_started  # not_started | in_progress | completed | on_hold | blocked
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# [Title] - Technical Implementation Plan

<!--
This plan focuses on HOW — the technical approach, key decisions, and constraints.

IMPORTANT: This plan will be executed by an AI agent in a fresh context window.
Write it like a brief from a tech lead to a senior engineer: state the approach,
the decisions that matter, and the constraints that must be respected. Do NOT
write step-by-step instructions or list every file/field/command. The implementing
agent should have freedom to choose the best implementation path.

A good plan is 50-100 lines. If yours is over 150, you're probably over-specifying.
-->

## Approach

<!--
2-4 paragraphs covering:
- Overall technical strategy and why
- Key technology decisions (and why, if non-obvious)
- Anything the implementing agent MUST do a specific way (vs. things they can decide)

Focus on decisions and constraints, not steps.
-->

[Describe the technical approach here]

## Key Decisions & Constraints

<!--
Bullet list of things the implementing agent needs to know but shouldn't have to
re-derive. These are the "don't mess this up" items — things where making the
wrong call would require rework or violate a requirement.

Keep each item to 1-2 lines. If you're writing paragraphs, it belongs in the
Approach section or the spec.
-->

- [Decision or constraint 1]
- [Decision or constraint 2]

## Milestones

<!--
3-7 high-level milestones that define the arc of the work. NOT individual tasks.
Think "what would you demo at each checkpoint?" not "what commands do you run?"

Bad:  "- [ ] Run npm init"
Good: "- [ ] Project scaffolded and building locally"

Bad:  "- [ ] Create users table with id, email, name, created_at columns"
Good: "- [ ] Database schema covers all core entities"
-->

- [ ] [Milestone 1]
- [ ] [Milestone 2]
- [ ] [Milestone 3]

## Affected Systems

<!--
Which repos and/or external systems will be modified?
One line per system — repo name and what kind of changes.
-->

- **[Repo/System]** — [What changes at a high level]

## Risks

<!--
Optional. Only include risks that are non-obvious or require specific mitigation.
Skip this section if the work is straightforward.
-->

| Risk | Mitigation |
|------|------------|
| [Risk 1] | [How to mitigate] |

## Notes

<!--
Optional. Context that doesn't fit elsewhere — gotchas, things the implementing
agent should watch out for, or decisions that are intentionally left open for
them to make.
-->

[Additional notes]
