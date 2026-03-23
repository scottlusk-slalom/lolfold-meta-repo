---
type: project_plan
status: draft           # draft | active | completed | archived
increment: ""           # e.g., "Q1 2025", "PI 24.1", "Phase 1"
start_date: YYYY-MM-DD
end_date: YYYY-MM-DD
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# [Project/Increment Name] - Project Plan

<!--
PURPOSE: Capture the scope and context for a bounded increment of work.
Generated at kickoff/discovery, referenced throughout the increment.

SCOPE: Increment-specific planning that captures intent at a point in time.
This is a reference point, not a source of truth. Details live in:
- requirements/ for detailed PRDs and epics
- architecture/ for technical decisions and design

UPDATES: Update sparingly. Major scope changes warrant a new increment plan.
-->

## Increment Overview

### Name
[Increment or project phase name, e.g., "Q1 2025 - Foundation Sprint"]

### Timeframe
- **Start**: [YYYY-MM-DD]
- **End**: [YYYY-MM-DD]
- **Duration**: [X weeks/months]

### Objective
<!--
One paragraph describing what this increment aims to accomplish.
What does "done" look like at the end of this period?
-->

[Increment objective - what we're trying to achieve]

## Vision for This Increment

<!--
What success looks like at the end of this increment.
Keep it inspirational but grounded in reality.
-->

[Vision statement for this specific increment]

## Team & Roles

<!--
Who is working on this increment. Keep high-level.
Detailed responsibilities can live in a team charter or project management tool.
-->

### Core Team
| Name | Role | Focus Area |
|------|------|------------|
| [Name] | [Role, e.g., Tech Lead] | [Primary responsibility] |
| [Name] | [Role, e.g., Developer] | [Primary responsibility] |
| [Name] | [Role, e.g., Designer] | [Primary responsibility] |

### Subject Matter Experts (SMEs)
| Name | Domain | Engagement |
|------|--------|------------|
| [Name] | [Domain expertise] | [How/when to engage] |
| [Name] | [Domain expertise] | [How/when to engage] |

### Key Stakeholders
| Name/Group | Interest | Communication |
|------------|----------|---------------|
| [Name/Group] | [What they care about] | [How we keep them informed] |
| [Name/Group] | [What they care about] | [How we keep them informed] |

## Scope Summary

<!--
High-level themes and epics for this increment.
This section captures INTENT at kickoff. Detailed requirements live in requirements/.
As requirements are created, link to them here.
-->

### Themes / Epics

#### [Theme 1: Name]
[Brief description of this theme and its business value]

**Related Requirements**:
- `requirements/prd-[feature-name].md` (if exists)
- [Or note: "To be created"]

#### [Theme 2: Name]
[Brief description of this theme and its business value]

**Related Requirements**:
- `requirements/prd-[feature-name].md` (if exists)
- [Or note: "To be created"]

#### [Theme 3: Name]
[Brief description of this theme and its business value]

**Related Requirements**:
- `requirements/prd-[feature-name].md` (if exists)
- [Or note: "To be created"]

### Out of Scope for This Increment
<!--
Explicitly call out what we're NOT doing this increment.
Helps prevent scope creep and sets expectations.
-->

- [Item explicitly deferred]
- [Item explicitly deferred]
- [Item explicitly deferred]

## Technical Context

<!--
Summary of technical approach for this increment.
Detailed architecture lives in architecture/ directory.
-->

### Tech Stack Summary
<!--
High-level overview. Link to source of truth for details.
-->

| Layer | Technology | Notes |
|-------|------------|-------|
| [Frontend/Backend/etc.] | [Technology] | [Brief note] |
| [Database] | [Technology] | [Brief note] |
| [Infrastructure] | [Technology] | [Brief note] |

**Detailed Stack**: See `architecture/tech-stack.md`

### Key Technical Decisions
<!--
Link to relevant ADRs or note decisions made at kickoff.
-->

- [Decision 1]: See `architecture/adr/[number]-[name].md`
- [Decision 2]: [Brief summary if no ADR yet]

### Technical Constraints
<!--
Constraints that specifically impact this increment.
-->

- [Constraint 1]
- [Constraint 2]

## Assumptions & Constraints

### Assumptions
<!--
Things we're assuming to be true for planning purposes.
If these prove false, the plan may need to change.
-->

1. [Assumption about resources, timeline, dependencies, etc.]
2. [Assumption about technical feasibility]
3. [Assumption about stakeholder availability]

### Constraints
<!--
Hard limitations we must work within.
-->

- **Budget**: [Budget constraint, if applicable]
- **Timeline**: [Why the end date matters]
- **Resources**: [Team capacity constraints]
- **Technical**: [Technical limitations]

## Risks

<!--
Known risks for this increment. Keep it focused on this period of work.
-->

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [How we'll address it] |
| [Risk 2] | High/Med/Low | High/Med/Low | [How we'll address it] |
| [Risk 3] | High/Med/Low | High/Med/Low | [How we'll address it] |

## Dependencies

<!--
External factors that could impact this increment.
-->

### Internal Dependencies
- **[Team/System]**: [What we need from them and when]
- **[Team/System]**: [What we need from them and when]

### External Dependencies
- **[Vendor/Partner]**: [What we need and timeline]
- **[Decision/Approval]**: [What needs to happen and when]

## Success Criteria

<!--
How we'll know this increment succeeded.
These should be verifiable at the end of the increment.
-->

### Deliverables
- [ ] [Concrete deliverable 1]
- [ ] [Concrete deliverable 2]
- [ ] [Concrete deliverable 3]

### Outcomes
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]

### Acceptance Criteria
<!--
What must be true for stakeholders to consider this increment complete?
-->

- [ ] [Acceptance criterion 1]
- [ ] [Acceptance criterion 2]

## Key Milestones

<!--
Major checkpoints during this increment.
Keep high-level; detailed sprint/iteration planning happens elsewhere.
-->

| Milestone | Target Date | Description |
|-----------|-------------|-------------|
| [Milestone 1] | [Date] | [What it represents] |
| [Milestone 2] | [Date] | [What it represents] |
| [Milestone 3] | [Date] | [What it represents] |

## References

<!--
Links to related documentation.
-->

- **Product Brief**: `./project/product-brief.md`
- **Requirements**: `./requirements/`
- **Architecture**: `./architecture/`
- **Previous Increment**: `./project/[previous-plan].md` (if applicable)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| YYYY-MM-DD | [Name] | Initial draft at kickoff |
