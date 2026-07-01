# /scaffold-project

Interactive project context scaffolding for greenfield development. Takes a new meta-repo from bootstrapped to spec-ready by generating all required project context files.

## Usage
/scaffold-project [--non-interactive] [--dry-run]

## Behavior

### Step 1: Interview

Gather the following from the user (skip any already populated in AGENTS.md):

1. **Project name** — official name for this initiative
2. **One-line description** — what it does in 10 words or less
3. **Primary stack** — e.g., "NestJS + PostgreSQL + Next.js"
4. **Target users** — who is this for? (1-2 sentences)
5. **Core problem** — what pain does this solve? (1-2 sentences)
6. **Team size** — how many developers?
7. **Increment scope** — what's the first phase of work? (1-2 sentences)
8. **Repos planned** — list repo names and their purpose (e.g., "my-api: backend REST service, my-web: Next.js frontend")
9. **Testing strategy** — preferred test frameworks (jest, vitest, pytest, etc.)
10. **Deployment model** — SaaS, on-premise, hybrid, serverless, etc.

If `--non-interactive`, halt with error: "Cannot scaffold without project context. Remove --non-interactive or populate AGENTS.md manually."

### Step 2: Generate Project Context

Using interview answers, generate the following files:

#### 2a: Update `AGENTS.md`
Fill in the header block:
```
**Project: <project name>**
**Description:** <one-line description>
**Stack:** <primary stack>
**Repos:** See `project/project-repositories.yaml`
```

#### 2b: Generate `project/product-brief.md`
Use template from `docs/templates/product-brief.md`. Fill in:
- Product name, tagline, summary
- Problem statement (current state / desired state)
- Target users
- Core capabilities (derived from repos and scope)
- Technical boundaries (stack, deployment model)
- Leave metrics and competitive landscape as TODOs

#### 2c: Generate `project/project-plan.md`
Use template from `docs/templates/project-plan.md`. Fill in:
- Increment name (derived from scope)
- Timeframe: start = today, end = "TBD"
- Objective (from increment scope)
- Team (from team size — use placeholder names with roles)
- Themes (from repos and scope)
- Tech stack table (from primary stack)
- Leave risks and dependencies as TODOs

#### 2d: Generate `project/project-repositories.yaml`
For each repo from interview:
```yaml
repositories:
  <repo-name>:
    purpose: <purpose from interview>
    description: >
      <expanded description>
    local_path: repos/<repo-name>
    default_gate_level: minimal
    status: proposed
    git:
      organization: <prompt or use GP_GITHUB_ORG env>
      repository: <repo-name>
      clone_url: https://github.com/<org>/<repo-name>.git
      default_branch: main
    when_to_use:
      - <derived from purpose>
```

#### 2e: Generate `architecture/context-index.md`
Populate the "Load by Task" table with entries based on the repos and stack:
- Map each repo to likely task types
- Fill in document paths (even if docs don't exist yet — mark as "TO CREATE")

### Step 3: Gap Analysis

Before presenting output, analyze the generated content for gaps that require human judgment:

1. **Ambiguity gaps** — Where the interview answers were vague or contradictory:
   - E.g., "Is the API public-facing or internal-only? This affects auth strategy."
   - E.g., "You mentioned both PostgreSQL and DynamoDB — which is primary vs. cache?"

2. **Assumption gaps** — Where the AI inferred something that could be wrong:
   - E.g., "I assumed a monorepo structure — should these be separate GitHub repos instead?"
   - E.g., "I placed auth in the API repo — should it be a shared library?"

3. **Decision gaps** — Choices the AI cannot make on the user's behalf:
   - E.g., "Testing strategy: unit-only (fast) vs. integration-heavy (thorough but slower CI)?"
   - E.g., "Gate level: `minimal` is fastest to start; `standard` catches more issues. Which do you prefer?"

4. **Missing context gaps** — Information not provided that would improve output quality:
   - E.g., "No deployment target specified — this affects infra patterns in the context-index."
   - E.g., "No existing design system mentioned — should the frontend follow a specific component library?"

Present ALL gaps to the user as a numbered list. Format:

```
## Gaps Requiring Your Input

Before I write the files, I need your input on:

1. [AMBIGUITY] You said "microservices" but listed one repo — is this a monolith to start, splitting later?
2. [ASSUMPTION] I'll assume JWT for auth since you chose NestJS. Correct?
3. [DECISION] Gate level for repos: minimal (ship fast) or standard (stricter quality)?
4. [MISSING] No CI/CD preference stated — GitHub Actions, GitLab CI, or other?
```

**HALT here and wait for user response.** Do NOT proceed to file generation until gaps are resolved or explicitly deferred by the user.

If the user says "skip" or "use your best judgment" for a gap, document the assumption made in `context/decisions.md` of the first spec created later.

### Step 4: Human Review Gate

After resolving gaps, generate all files (Step 2) but do NOT finalize. Instead:

1. **Present a summary** of what was generated:
   ```
   ## Generated Files — Review Before Finalizing

   ### AGENTS.md (header update)
   Project: MyProject | Stack: NestJS + PostgreSQL + Next.js

   ### product-brief.md
   - Problem: [2-sentence summary]
   - Users: [who]
   - Capabilities: [list]

   ### project-plan.md
   - Increment: [name]
   - Themes: [list]
   - Repos: [count] repos at gate level [level]

   ### project-repositories.yaml
   - my-api (proposed) — Backend REST service
   - my-web (proposed) — Next.js frontend

   ### context-index.md
   - [N] task-type mappings added
   ```

2. **Ask explicitly:**
   ```
   Does this look right? You can:
   - Say "looks good" to finalize all files
   - Point out specific issues (e.g., "change gate level to standard", "add a worker repo")
   - Say "show me [file]" to see the full generated content before finalizing
   ```

3. **Iterate** on user feedback. Re-generate affected files only. Loop until user approves.

4. **Only after explicit user approval**, write all files to disk.

### Step 5: Validate

Run validation checks:
- [ ] `AGENTS.md` has project name, description, stack filled in
- [ ] `project/product-brief.md` exists and has no empty required sections
- [ ] `project/project-plan.md` exists and has increment objective
- [ ] `project/project-repositories.yaml` passes `./scripts/validate-repos-yaml.sh`
- [ ] `architecture/context-index.md` exists and has ≥1 entry in "Load by Task"

Report results. All checks must pass for READY status.

### Step 6: Next Steps

Print:
```
✓ Project scaffolded successfully.

Next steps:
1. Register your first repo:  /register-repo <name> --status proposed
2. Scaffold repo from template: /scaffold-repo <name> --template <nestjs|nextjs|worker>
   — OR clone existing repo to repos/<name>/ and run: /init-repo repos/<name>
3. Create your first feature spec: /generate-spec my-first-feature "brief description" --type feature
4. See docs/how-to/greenfield-first-feature.md for a full walkthrough
```

## Reads
- `AGENTS.md` (to check if already populated)
- `docs/templates/product-brief.md`
- `docs/templates/project-plan.md`

## Writes
- `AGENTS.md` (updates header block only)
- `project/product-brief.md`
- `project/project-plan.md`
- `project/project-repositories.yaml`
- `architecture/context-index.md` (updates "Load by Task" table)

## Delegates To
- `./scripts/validate-repos-yaml.sh`

## Halt Conditions
- `--non-interactive` without pre-populated AGENTS.md
- User declines to provide project name (minimum required field)
