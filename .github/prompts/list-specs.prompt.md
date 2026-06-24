---
description: Show all specs in the repository organized by type and status
name: list-specs
agent: agent
---

Show all specs in the repository organized by type and status.

## Instructions

1. Search for all spec directories in `specs/*/`

2. For each spec found:
   - Read the YAML front matter from the `.spec.md` file
   - Extract: type, status, priority, created date, and tags

3. Display the specs in a formatted table grouped by status:
   - **Active Specs** (status: active)
   - **Draft Specs** (status: draft)
   - **Completed Specs** (status: completed)
   - **Archived Specs** (status: archived)

4. For each spec, show:
   - Type (feature/bug/chore/design/planning)
   - Name (from directory name)
   - Priority (if set)
   - Created date
   - Brief summary (first line of "Problem Statement" or "Objectives" section)

5. Include a count of specs by type and status at the end.

Example output format:
```
## Active Specs (2)

| Type    | Name              | Priority | Created    | Summary                                  |
|---------|-------------------|----------|------------|------------------------------------------|
| chore   | meta-repo-setup   | high     | 2025-12-11 | Establish meta-repository structure      |
| feature | user-auth         | medium   | 2025-12-15 | Add authentication system                |

## Draft Specs (1)

| Type    | Name              | Priority | Created    | Summary                                  |
|---------|-------------------|----------|------------|------------------------------------------|
| design  | api-gateway       | low      | 2025-12-16 | Evaluate API gateway options             |

---
Summary: 3 total specs (2 active, 1 draft)
By type: 1 chore, 1 feature, 1 design
```
