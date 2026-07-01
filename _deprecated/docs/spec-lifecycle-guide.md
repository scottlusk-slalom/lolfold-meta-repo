# Spec Lifecycle Guide

A step-by-step guide to orchestrating work through the spec lifecycle.

## Overview

Every unit of work follows this progression:

```
/generate-spec  →  /approve-spec  →  /execute-spec  →  /archive-spec
  specified          planned           executed/submitted    archived
```

Each stage has a gate that must be cleared before the next can begin.

---

## 1. Generate a Spec (`/generate-spec`)

**When**: You have a requirement, bug report, or piece of work to formalize.

**What happens**:
1. The harness gathers context from `org/`, `project/`, and `architecture/`
2. You describe what you want to build/fix/change
3. The spec-writer agent asks clarifying questions
4. It analyzes the target codebase(s)
5. It generates:
   - `{name}.spec.md` — the functional specification (WHAT and WHY)
   - `{name}.plan.md` — the technical plan (HOW)
   - `status.md` — lifecycle tracker
   - `context/scratch/` — populated with analysis findings

**Your role**: Answer questions, provide requirements, review the output.

**Result**: A complete spec directory at `specs/{type}/{name}/` with status **specified**.

### Example

```
> /generate-spec

What do you want to build?
> Add OAuth2 login to the dashboard app

Type? feature
Name? oauth2-dashboard-login
Target repo? dashboard-app

[Agent analyzes codebase, asks 2-3 clarifying questions]
[Generates spec + plan]

✓ Spec created: specs/feature/oauth2-dashboard-login/
  Status: specified
```

---

## 2. Approve the Spec (`/approve-spec`)

**When**: You've reviewed the generated spec and plan and are satisfied they're ready for implementation.

**What happens**:
1. The harness presents a review checklist:
   - Spec completeness (problem, criteria, scope, risks)
   - Plan readiness (tasks, test mapping, rollback)
   - Context readiness (repos identified, no conflicts)
2. You approve, request changes, or reject

**Your role**: Review the spec critically. This is the last gate before code is written.

**Result**: Status transitions to **planned**. The approval gate is recorded with your name and date.

### Example

```
> /approve-spec

Reviewing: specs/feature/oauth2-dashboard-login

Checklist:
  ✓ Problem statement clear
  ✓ Success criteria testable
  ✓ Scope boundaries explicit
  ✓ Dependencies available
  ⚠ Risk: OAuth provider rate limits not addressed

Decision? approve (with note about rate limits)

✓ Spec approved: specs/feature/oauth2-dashboard-login
  Status: planned
  Ready for /execute-spec
```

---

## 3. Execute the Spec (`/execute-spec`)

**When**: The spec is approved and you're ready to implement.

**What happens** (5 stages):

### Stage 1: Worktree Setup
- Creates branch `spec/feature/oauth2-dashboard-login`
- Creates isolated git worktree
- Installs dependencies, verifies clean build

### Stage 2: RED/GREEN/Refactor
For each task in the plan:
- **RED** — Write failing tests for the success criterion
- **GREEN** — Write minimal code to pass
- **Refactor** — Clean up, keeping tests green
- Commits after each phase

### Stage 3: Validate
- Runs full test suite
- Checks coverage hasn't decreased
- Maps success criteria → test coverage
- Generates risk assessment

### Stage 4: Adversarial Review
- The reviewer agent attacks the implementation
- Checks security, edge cases, performance
- Produces a verdict: PASS / PASS_WITH_NOTES / FAIL
- **FAIL blocks PR submission** — issues must be fixed first

### Stage 5: Submit PR
- Pushes branch, creates PR with spec linkage
- PR body includes summary, changes, coverage, risk, review verdict

**Your role**: Monitor progress. You'll be consulted if the review fails or if the troubleshooter can't resolve an issue autonomously.

**Result**: Status transitions to **submitted**. You get a PR URL.

### Example

```
> /execute-spec

Pre-flight: Checking approval gate...
✓ Approved by bernice on 2026-06-24

Stage 1: Creating worktree... ✓
Stage 2: Implementing (4 tasks)
  [1/4] RED ✓ → GREEN ✓ → Refactor ✓
  [2/4] RED ✓ → GREEN ✓ → Refactor ✓
  [3/4] RED ✓ → GREEN ✗ (troubleshooter invoked → fixed) → GREEN ✓ → Refactor ✓
  [4/4] RED ✓ → GREEN ✓ → Refactor ✓
Stage 3: Validation
  Tests: 47/47 passing
  Coverage: 89% (+3%)
  Risk: medium (auth changes)
Stage 4: Adversarial review
  Verdict: PASS_WITH_NOTES
  Note: Consider adding token refresh retry logic
  [Accept notes and proceed? yes]
Stage 5: PR submitted

✓ PR: https://github.com/org/dashboard-app/pull/142
  Status: submitted
```

---

## 4. Archive the Spec (`/archive-spec`)

**When**: The PR is merged and the work is complete.

**What happens**:
1. The context-curator agent analyzes scratch memory
2. Valuable findings are promoted:
   - Spec-specific decisions → `context/`
   - Cross-cutting patterns → `architecture/` or `project/`
   - Org-wide learnings → `org/`
3. Scratch memory is cleaned up
4. Cloned repos are removed (after confirming changes were pushed)
5. Status set to **archived** with summary

**Your role**: Confirm which findings to promote and where.

**Result**: Status transitions to **archived**. Knowledge is preserved in the right tier. Working files are cleaned up.

### Example

```
> /archive-spec

Analyzing scratch memory (6 files)...

Promotions proposed:
  → context/: OAuth provider quirks doc
  → architecture/: Auth flow sequence diagram
  → org/patterns.md: Token refresh retry pattern

Accept promotions? yes

Cleanup:
  - Scratch: 6 files deleted
  - Worktree: removed
  - Cloned repo: removed (changes pushed to PR #142)

✓ Spec archived: specs/feature/oauth2-dashboard-login
  Commit: "chore: archive spec oauth2-dashboard-login"
```

---

## Quick Reference

| Command | Prerequisite | Output | Status After |
|---------|-------------|--------|--------------|
| `/generate-spec` | None | Spec + plan + status + scratch | specified |
| `/approve-spec` | Status = specified | Approval recorded | planned |
| `/execute-spec` | Approval gate = approved | Worktrees → code → review → PR | submitted |
| `/archive-spec` | PR merged / work done | Context promoted, cleanup | archived |

## Tips

- **Don't skip approval.** The gate exists to catch scope creep and missing criteria before code is written.
- **Let the troubleshooter work.** If Stage 2 hits a snag, the troubleshooter agent handles most test/build failures autonomously.
- **Review the adversarial findings.** PASS_WITH_NOTES means the reviewer found something worth knowing — read the notes even if you proceed.
- **Archive promptly.** Scratch memory loses value over time. Promote findings while context is fresh.
- **Use `/list-specs`** to see all specs and their current lifecycle state at any time.
