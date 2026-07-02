# Greenfield: Your First Feature (End-to-End Walkthrough)

This guide takes you from "I have a scaffolded project" to "I have a working feature with tests, reviewed and submitted as a PR." Follow these steps after running `/scaffold-project`.

---

## Prerequisites

- Meta-repo bootstrapped (`./scripts/bootstrap.sh`)
- Project context generated (`/scaffold-project`)
- At least one repo registered and loop-ready (`/scaffold-repo` or `/init-repo`)

Verify readiness:
```
/repo-status
```
All target repos should show READY.

---

## Step 1: Pick Your First Feature

Choose something small, vertical, and testable. Good first features:

| Pattern | Example Brief | Why It's Good |
|---------|--------------|---------------|
| Health endpoint | "Add GET /health that returns 200 with version" | Proves CI, deploy, and test pipeline work |
| CRUD entity | "Create REST endpoints for managing users" | Touches DB, validation, error handling |
| Auth skeleton | "Add JWT authentication middleware" | Cross-cutting, used by everything else |
| Landing page | "Create landing page with nav and hero section" | Proves frontend build, routing, component patterns |

**Recommendation:** Start with a health endpoint or simple CRUD. It validates your entire pipeline with minimal risk.

---

## Step 2: Generate the Spec

```
/generate-spec health-endpoint "Add GET /health endpoint returning 200 with service name and version" --type feature
```

This creates:
```
specs/feature/health-endpoint/
├── health-endpoint.spec.md    ← functional specification
├── health-endpoint.plan.md    ← implementation plan (empty until /plan-impl)
├── status.md                  ← tracking
└── context/
    ├── CONTEXT.md             ← curated reference docs
    ├── requirements.md        ← REQ-1, REQ-2, ... (auto-generated)
    └── decisions.md           ← design decisions log
```

### What Happens Automatically

1. **Requirements agent** turns your brief into testable requirements:
   ```
   REQ-1: GET /health returns HTTP 200
   REQ-2: Response body includes { service: string, version: string }
   REQ-3: Endpoint responds within 100ms under normal load
   ```

2. **Context curator** pulls relevant docs from `architecture/` into `context/`

3. **Spec writer** produces the full specification

### Review the Spec

Open `specs/feature/health-endpoint/health-endpoint.spec.md` and verify:
- Problem statement makes sense
- Success criteria are specific and testable
- Scope boundaries are correct
- No `⚠️ DESIGN DECISION REQUIRED` markers (if present, resolve them first)

---

## Step 3: Approve the Spec

```
/approve health-endpoint
```

This moves status from `specified` → `planned`, signaling the spec is ready for execution.

---

## Step 4: Plan the Implementation

```
/plan-impl health-endpoint
```

This produces `health-endpoint.plan.md` with:
- Task breakdown (ordered, with file-level guidance)
- Dependency map
- Test strategy per task
- Acceptance criteria mapping (REQ → test)

### Review the Plan

Check that:
- Tasks are ordered correctly (dependencies first)
- Each task has a clear test strategy
- File paths match your repo structure
- No unnecessary abstractions or over-engineering

---

## Step 5: Execute (TDD Loop)

### Option A: Single-Repo Execution (Simpler)

If your feature touches only one repo:

```
/execute-impl health-endpoint --repo my-api
```

### Option B: Multi-Repo Loop (Full Orchestration)

If your feature spans multiple repos:

```
/multi-repo-loop health-endpoint
```

### What Happens During Execution

For each task in the plan, the harness runs a strict TDD cycle:

```
RED    → Write a failing test for the requirement
GREEN  → Write minimal code to make it pass
REFACTOR → Clean up without changing behavior
COMMIT → Atomic commit with conventional message
VERIFY → Run full test suite, check coverage
```

**Hard gate:** If no new tests are added, execution halts. Every feature must have tests.

### If Execution Fails

Common reasons and fixes:

| Failure | Cause | Fix |
|---------|-------|-----|
| "No new tests detected" | Test file not in expected location | Check `_loop-config.yaml` test patterns |
| Build failure | Missing dependency | Install in the worktree, re-run |
| Coverage below threshold | Tests don't cover new code | Lower threshold in `_loop-config.yaml` or add tests |
| Dependency check fails | Required service not running | Start the service or use `--skip-deps` |

---

## Step 6: Review

```
/review-impl health-endpoint
```

The adversarial reviewer checks:
- Test quality (are tests meaningful or trivial?)
- Edge cases (error handling, boundary conditions)
- Code patterns (matches repo conventions?)
- Security (no injection, no secrets in code)
- Performance (no obvious bottlenecks)

If issues are found, they're reported with severity. Fix critical/high issues before proceeding.

---

## Step 7: Submit PR

```
/submit-pr health-endpoint
```

This:
1. Pushes the feature branch (`feat/health-endpoint`)
2. Opens a PR with spec-derived description
3. Updates gate status to `submitted`

---

## Step 8: Finalize

After the PR is merged:

```
/finalize-spec health-endpoint
```

This:
1. Archives the spec to `specs/archive/`
2. Runs a retrospective (what went well, what didn't)
3. Promotes durable learnings to project/org tier

---

## Complete Example: Health Endpoint

Here's the full sequence for a NestJS health endpoint:

```bash
# Generate spec
/generate-spec health-endpoint "Add GET /health returning 200 with service name and version from package.json" --type feature

# Review and approve
/approve health-endpoint

# Plan
/plan-impl health-endpoint

# Execute (single repo)
/execute-impl health-endpoint --repo my-api

# Review
/review-impl health-endpoint

# Submit
/submit-pr health-endpoint

# After merge
/finalize-spec health-endpoint
```

**Total time (typical):** 5-15 minutes for a simple feature, depending on build/test speed.

---

## Common Patterns for Greenfield Features

### Pattern: CRUD API

```
/generate-spec user-crud "Create REST endpoints for users: POST /users, GET /users/:id, PUT /users/:id, DELETE /users/:id with PostgreSQL persistence" --type feature
```

The spec writer will produce requirements for:
- Input validation
- Error responses (404, 400, 409)
- Database schema
- Integration tests

### Pattern: Authentication

```
/generate-spec auth-jwt "Add JWT authentication: login endpoint, token validation middleware, protected route decorator" --type feature
```

### Pattern: Frontend Page

```
/generate-spec landing-page "Create marketing landing page with responsive hero section, feature grid, and CTA button linking to /signup" --type feature
```

### Pattern: Background Worker

```
/generate-spec email-worker "Create background job processor that sends welcome emails on user.created events from the message queue" --type feature
```

---

## Tips for Greenfield Success

1. **Start small.** Your first spec should be trivially simple. Validate the pipeline before tackling complex features.

2. **One repo at a time.** Get one repo fully loop-ready before adding more. Multi-repo orchestration adds complexity.

3. **Trust the TDD cycle.** The RED→GREEN→REFACTOR loop prevents over-engineering. Let it guide you.

4. **Review the generated spec.** The AI-generated spec is a draft. Spend 2 minutes reading it before approving — catching a wrong assumption here saves 10 minutes in execution.

5. **Keep briefs specific.** "Add user management" is too vague. "Add POST /users with email validation and unique constraint" is specific enough for good requirements generation.

6. **Use `--type` correctly:**
   - `feature` — new capability
   - `bug` — fix broken behavior
   - `chore` — refactoring, dependency updates, CI changes
   - `design` — architecture decisions, spikes, prototypes

7. **Check gate status.** After execution, run `/repo-status` to confirm everything passed. Fix issues before submitting.

---

## Troubleshooting

### "I don't have `architecture/context-index.md`"

Run `/scaffold-project` — it generates this file. Or create it manually following the template in `architecture/context-index.md`.

### "My repo isn't in `project-repositories.yaml`"

Register it first:
```
/register-repo my-repo --status proposed
```

### "`/execute-impl` says repo isn't loop-ready"

Run `/init-repo repos/<name>` to generate `_loop-config.yaml` and validate setup.

### "Spec generation produced empty requirements"

Your brief was too vague. Be specific about endpoints, data, or user actions. Include HTTP methods, response shapes, or UI elements.

### "I want to skip Golden Path validation"

Use `--skip-gp` flag on `/init-repo`. Golden Path is advisory for greenfield projects without a platform handbook.

---

## What's Next After Your First Feature?

1. **Add more features** — Build out your backlog one spec at a time
2. **Onboard more repos** — `/scaffold-repo` or `/init-repo` for additional services
3. **Set up CI/CD** — Connect your repos to GitHub Actions or your CI system
4. **Populate Golden Path** — Define platform rules as your patterns stabilize
5. **Use `/decompose-phase`** — Break larger initiatives into independently shippable slices
