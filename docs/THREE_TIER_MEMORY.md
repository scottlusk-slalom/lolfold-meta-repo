# Three-Tier Memory System

This document describes the memory architecture used to provide context to AI agents across different scopes.

## Overview

The three-tier memory system organizes context into three persistent tiers plus a volatile scratch tier:

| Tier | Scope | Location | Persistence |
|------|-------|----------|-------------|
| **Org** | Enterprise-wide | External (cached locally) | Long-term, shared |
| **Project** | This meta-repo | `architecture/`, `project/`, `requirements/` | Long-term, project-specific |
| **Repo** | Individual repositories | Within cloned repos | Long-term, repo-specific |
| **Scratch** | Active spec work | `specs/*/context/scratch/` | Volatile, task-specific |

### Quick Example

Imagine implementing a user authentication feature:

1. **Org tier**: Your company mandates OAuth2 + MFA (cached in `org/standards/security.md`)
2. **Project tier**: Your project chose Auth0 as the provider (documented in `architecture/auth-strategy.md`)
3. **Repo tier**: Backend repo has existing auth middleware patterns (in `repo/backend/docs/auth.md`)
4. **Spec tier**: Your spec adds biometric login option (in `specs/feature/07-biometric-auth/`)
5. **Scratch**: You discover Auth0's WebAuthn API quirks while implementing (notes in `context/scratch/webauthn-findings.md`)

When complete:
- Promote WebAuthn quirks to project tier (other specs will need it)
- Commit biometric middleware to backend repo
- Delete spec directory (work is in git history)
- Scratch notes about Auth0 API helped you succeed, then disappeared

## Tier Details

### Org Tier

Enterprise-level context that applies across projects:
- API design standards
- Security conventions
- Architecture patterns
- Coding standards

**Location:** External systems (other repos, Confluence, etc.)
**In meta-repo:** Cached copies optionally stored in `org/` directory

**Important:** Org-level memory is optional and implementation-specific. Use this tier only when:
- External systems of record contain important context
- That context should be cached locally for reference
- The context applies across multiple projects

#### Org-Level Cache Conventions (When Used)

Some projects have no org-level cache. Others may cache enterprise standards, architectural patterns, or compliance requirements. Whether enterprise architecture lives in "org" or "project" tier depends on your context:

- **Org tier:** Enterprise-wide architecture standards that apply to all projects
- **Project tier:** Architecture specific to this project or product line

**When org-level cache is needed**, follow these conventions:

**Cache Directory Structure:**
```
org/                           # Optional directory, create only when needed
├── cache.yaml                 # Cache metadata and refresh configuration
├── standards/
│   ├── api-design.md          # Example: cached API standards
│   ├── security-standards.md
│   └── coding-conventions.md
├── patterns/
│   ├── microservices.md       # Example: cached architecture patterns
│   └── event-driven.md
└── templates/
    └── ...
```

**Cache Metadata Example (`org/cache.yaml`):**
```yaml
# Cache configuration for org-level context
refresh_strategy: manual  # manual | weekly | monthly
last_refreshed: 2025-12-11T10:00:00Z

sources:
  - name: api-design
    source_url: https://internal-wiki.example.com/api-standards
    local_path: standards/api-design.md
    last_sync: 2025-12-11T10:00:00Z

  - name: security-standards
    source_url: https://github.com/example-org/security-standards
    local_path: standards/security-standards.md
    last_sync: 2025-12-01T10:00:00Z
```

**Refresh Conventions:**

1. **Manual Refresh (Default):**
   - Update org-level cache explicitly when standards change
   - Document cache age in `cache.yaml`
   - AI agents should note when cache is stale (>30 days)

2. **Automated Refresh (Optional):**
   - Implement refresh commands as needed (e.g., `/refresh-org-cache`)
   - Consider GitHub Actions to sync from source systems

3. **When to Refresh:**
   - Start of new projects
   - When standards are known to have changed
   - When cache is >30 days old
   - Before major architectural decisions

4. **Gitignore Considerations:**
   - `org/` directory should be **committed** (unlike scratch memory)
   - Allows version control of cached standards
   - Team members get org context on clone
   - If org sources contain secrets, document in `org/cache.yaml` but don't commit content

### Project Tier

Project-specific context stored in this meta-repo:

```
meta-repo/
├── architecture/      # C4 architecture documentation
│   ├── adr/          # Architecture Decision Records
│   ├── patterns/     # Reusable patterns for this project
│   └── contracts/    # API contracts, interfaces
├── project/          # Product briefs, charters
│   ├── product-brief.md
│   └── project-charter.md
└── requirements/     # PRDs, test strategy
    ├── prd-feature-name.md
    └── test-strategy.md
```

This tier represents the **functional scope** of the project - what we're building and why.

**Example Project Tier Content:**

```markdown
# architecture/adr/003-async-job-pattern.md
# ADR 003: Background Job Processing with Celery

## Status: Accepted

## Context
We need to handle long-running operations (report generation,
data imports) without blocking API requests.

## Decision
Use Celery with Redis as message broker for async job processing.

## Consequences
- All long-running operations must use Celery tasks
- Frontend polls /api/jobs/:id for status
- Jobs expire after 24 hours
```

```markdown
# requirements/prd-reporting.md
# Product Requirements: Reporting System

## Objectives
Enable users to generate and download custom reports.

## Requirements
- **Must Have:**
  - Export to CSV format
  - Support up to 100K rows
  - Async generation for reports >1000 rows

- **Should Have:**
  - Excel format support
  - Scheduled report generation
```

When working in a spec, you reference this project-tier context to understand:
- What patterns and decisions already exist
- What requirements you're implementing
- What the broader project architecture looks like

### Repo Tier

Repository-specific context stored within cloned repositories:
- AGENTS.md / CLAUDE.md - AI assistant instructions
- README.md - Repo documentation
- docs/ - Project documentation and guides
- .cursor/, .github/, .claude/ - Tool-specific configurations

**Location:** `specs/*/repo/[repo-name]/`

### Scratch Tier (Volatile)

Temporary context generated while working on a spec:

```
specs/feature/01-something/
├── 01-something.spec.md
├── 01-something.plan.md
├── context/
│   ├── [curated-context].md    # Context pulled from project tier
│   └── scratch/                # Volatile working memory (gitignored)
│       ├── notes.md
│       ├── research.md
│       └── ...
└── repo/
```

**Important:** Scratch memory is:
- Gitignored - not committed to version control
- Volatile - may be deleted when spec is archived
- Scoped - should not pollute neighboring specs
- Promotable - valuable findings may be promoted to project or repo tiers

#### Scratch Memory Conventions for AI Agents

Organize scratch memory with clear separation between reference materials and active working files:

**Recommended Structure:**
```
scratch/
├── references/          # Reference materials, copied docs, external resources
│   ├── api-docs.md
│   ├── requirements-extract.md
│   └── external-patterns.md
├── transcripts/         # Meeting notes, conversation logs, recorded discussions
│   ├── meeting-2025-12-11.md
│   ├── stakeholder-interview.md
│   └── design-discussion.md
├── notes.md            # General working notes (root level for quick access)
├── decisions.md        # Decision log with rationale
├── research.md         # Active research findings
└── [topic-specific]/   # Additional subdirectories as needed
    ├── repo-analysis/
    ├── integration-work/
    └── queries/
```

**When to Use Each Location:**

1. **`references/`** - Static reference materials:
   - Copied documentation from external sources
   - Extracted requirements or specifications
   - Architecture patterns from other projects
   - API documentation snapshots
   - Compliance or security guidelines

2. **`transcripts/`** - Recorded discussions:
   - Meeting notes (date-prefixed: `meeting-2025-12-11.md`)
   - Stakeholder interviews
   - Design review discussions
   - Decision-making conversations
   - User feedback sessions

3. **Root-level files** - Frequently accessed:
   - `notes.md` - General working notes, TODOs, questions
   - `decisions.md` - Decision log with context and rationale
   - `research.md` - Active investigation findings
   - `issues.md` - Blockers, problems, workarounds

4. **Topic-specific subdirectories** - As complexity grows:
   - `repo-analysis/` - Per-repo analysis files
   - `integration-work/` - Cross-repo integration notes
   - `queries/` - Test queries, investigation scripts
   - `outputs/` - Command outputs, logs, test results
   - `diagrams/` - Draft diagrams (promote polished ones to spec)

**File Naming Conventions:**
- Use lowercase with hyphens: `api-analysis.md`
- Prefix repo-specific files: `repo-backend-notes.md`
- Date-stamp meeting notes: `meeting-2025-12-11.md`
- Keep filenames descriptive but concise

**What NOT to Put in Scratch:**
- Final documentation (goes in spec or promoted to project tier)
- Secrets or credentials (use environment variables)
- Large binary files (reference external storage)
- Duplicate content from higher tiers (link instead)

**AI Agent Best Practices:**
1. **Start each work session** by reviewing existing scratch files
2. **Document as you work** - don't wait until the end
3. **Be specific** - future you (or another agent) needs context
4. **Link to sources** - reference repo files, docs, external URLs
5. **Mark promotion candidates** with `<!-- PROMOTE -->` comments
6. **Clean up periodically** - delete truly temporary notes
7. **Use references/ for static materials** - keep working files at root or in topic folders
8. **Date-stamp transcripts** - easy to track chronology of discussions

## Memory Flow

### Starting a Spec

When beginning work on a new spec, follow this workflow:

**1. Analyze Project-Tier Memory**

Review project-level context to understand constraints and patterns:

```bash
# Check architecture for relevant patterns and decisions
ls architecture/
cat architecture/adr/001-api-design.md

# Review requirements for feature context
ls requirements/
cat requirements/prd-user-management.md

# Check project documentation
cat project/product-brief.md
```

**Example:** You're working on `specs/feature/23-export-reports/`:
- Find `architecture/patterns/async-jobs.md` - project uses background jobs
- Find `requirements/prd-reporting.md` - requirements for report features
- Learn project uses Celery for async work, prefers CSV exports

**2. Curate Relevant Context**

Copy or create links to relevant project-tier content:

```bash
cd specs/feature/23-export-reports/

# Copy relevant architecture docs
mkdir -p context/
cp ../../architecture/patterns/async-jobs.md context/async-jobs-reference.md

# Extract relevant requirements
echo "# Report Export Requirements" > context/requirements-extract.md
echo "Extracted from requirements/prd-reporting.md" >> context/requirements-extract.md
# ... add relevant sections ...
```

This gives you quick access without hunting through project tier.

**3. Clone Relevant Repos**

```bash
cd specs/feature/23-export-reports/

# Clone the repos you'll modify
git clone git@github.com:yourorg/backend-api.git repo/backend-api
git clone git@github.com:yourorg/worker-service.git repo/worker-service

# Check out appropriate branches
cd repo/backend-api && git checkout develop
cd ../repo/worker-service && git checkout develop
```

**4. Initialize Scratch Memory**

Create initial working files:

```bash
cd context/scratch/

# Create initial working notes
cat > notes.md << 'EOF'
# Working Notes - Report Export Feature

## Initial Thoughts
- Need to add export endpoint to backend-api
- Background job will generate CSV in worker-service
- Should support both immediate (small) and async (large) exports

## Questions
- [ ] What's the size threshold for async vs immediate?
- [ ] Where do we store generated files? S3?
- [ ] How long to keep generated reports?
EOF

# Create subdirectories as needed
mkdir references transcripts repo-analysis
```

**5. Work and Document**

As you work, create scratch files naturally:

```bash
# After analyzing backend-api
echo "# Backend API Analysis" > scratch/repo-backend-api-analysis.md
echo "- Uses Express + TypeScript" >> scratch/repo-backend-api-analysis.md
echo "- Existing file upload uses S3" >> scratch/repo-backend-api-analysis.md

# After making a decision
echo "# Export Size Threshold Decision" > scratch/decisions.md
echo "Decided: 1000 rows = threshold" >> scratch/decisions.md
echo "Reasoning: Matches existing pagination limits" >> scratch/decisions.md

# After meeting with stakeholder
echo "# Stakeholder Meeting 2025-12-11" > scratch/transcripts/meeting-2025-12-11.md
echo "- Need Excel format in addition to CSV" >> scratch/transcripts/meeting-2025-12-11.md
```

**Complete Workflow Example:**

```
specs/feature/23-export-reports/
├── 23-export-reports.spec.md        # Created from template
├── 23-export-reports.plan.md        # Implementation plan
├── context/
│   ├── async-jobs-reference.md      # Copied from architecture/
│   ├── requirements-extract.md      # Curated from requirements/
│   └── scratch/
│       ├── notes.md                 # Working notes
│       ├── decisions.md             # Design decisions
│       ├── repo-backend-api-analysis.md
│       ├── repo-worker-analysis.md
│       ├── references/
│       │   └── s3-presigned-urls.md
│       └── transcripts/
│           └── meeting-2025-12-11.md
└── repo/
    ├── backend-api/                 # Cloned repository
    └── worker-service/              # Cloned repository
```

This structure keeps you organized and ensures all context is accessible.

### Completing a Spec

When a spec is completed, review scratch memory and promote valuable findings to appropriate tiers.

**Important:** Before executing any promotions, explain the plan to the user and get confirmation.

#### Memory Promotion Decision Matrix

| Content Type | Promote To | Example |
|--------------|------------|---------|
| Project-wide patterns/decisions | Project tier | Architecture decision records, cross-cutting patterns |
| Implementation details | Repo tier | Code comments, repo-specific docs |
| General reference materials | Project tier (`references/`) | Useful external docs, standards |
| Spec-specific findings | Keep in git history only | Alternatives considered, investigation notes |
| Truly temporary notes | Delete | Debug logs, scratch calculations |

#### Memory Promotion Routine

**Step 1: Review Scratch Memory**

```bash
# List all scratch files sorted by modification time
find specs/[type]/[id]-[name]/context/scratch -type f -exec ls -lt {} +
```

Look for files marked with `<!-- PROMOTE -->` comments or that contain:
- Reusable patterns or decisions
- Architecture insights applicable beyond this spec
- API integration patterns that other specs will need
- Security or compliance findings

**Step 2: Present Promotion Plan to User**

Before making any changes, explain to the user:
- What content you found in scratch memory
- Where you recommend promoting each piece (project tier, repo tier, or nowhere)
- Your rationale for each promotion
- What will be deleted

**Example:**
```
I found the following in scratch memory:

1. scratch/decisions.md - Contains authentication approach decision
   → RECOMMEND: Promote to architecture/adr/002-authentication-approach.md
   → REASON: This decision affects the entire project

2. scratch/repo-backend-api-guide.md - Backend API documentation
   → RECOMMEND: Promote to backend repo docs/
   → REASON: Useful for future backend development

3. scratch/references/oauth-spec.md - Copied OAuth2 specification
   → RECOMMEND: Do not promote (available externally)
   → ACTION: Delete

4. scratch/outputs/ - Test run logs
   → RECOMMEND: Delete
   → REASON: Temporary debug information

Do you approve this promotion plan? Any changes?
```

Wait for user confirmation before proceeding.

**Step 3: Execute Approved Promotions**

**Promote to Project Tier:**

When findings apply to the broader project:

```bash
# Example: Promoting architecture decision
cp specs/feature/01-auth/context/scratch/decisions.md \
   architecture/adr/002-authentication-approach.md
```

**Common project tier promotions:**
- **Architecture decisions** → `architecture/adr/[number]-[title].md`
- **Cross-cutting patterns** → `architecture/patterns/[pattern-name].md`
- **API contracts** → `architecture/contracts/[service]-api.md`
- **Reference materials** → `project/references/[topic].md`
- **Test strategies** → `requirements/[feature]-test-strategy.md`

**Promote to Repo Tier:**

When findings are repo-specific:

```bash
# Example: Promoting repo-specific documentation
cp specs/feature/01-auth/context/scratch/repo-backend-api-guide.md \
   specs/feature/01-auth/repo/backend/docs/api-guide.md

# Then commit in the cloned repo
cd specs/feature/01-auth/repo/backend
git add docs/api-guide.md
git commit -m "Add API guide from auth implementation work"
```

**Common repo tier promotions:**
- **Implementation notes** → Repo `docs/` directory
- **Architecture details** → Repo `ARCHITECTURE.md` or similar
- **Setup procedures** → Repo `README.md` updates
- **Code comments** → Inline documentation in code
- **Testing approaches** → Repo test documentation

**Step 4: Commit Promoted Content**

Commit all promoted content to git:

```bash
git add architecture/ project/ requirements/
git commit -m "Promote findings from [spec-name] to project tier"
git push origin [branch-name]
```

**Step 5: Archive or Delete Spec**

Once changes are pushed to origin, the spec work exists in git history. Choose:

**Option A: Delete Entirely (Recommended)**

```bash
# After confirming push to origin
rm -rf specs/[type]/[id]-[name]
git add specs/[type]/[id]-[name]
git commit -m "Complete and remove [spec-name] (preserved in git history)"
```

The spec remains in git history and can be retrieved if needed:
```bash
# To view historical spec
git log -- specs/[type]/[id]-[name]
git show [commit-hash]:specs/[type]/[id]-[name]/[id]-[name].spec.md
```

**Option B: Local Archive (Optional)**

Keep locally but don't commit:

```bash
# Create local archive (gitignored)
mkdir -p _archive/[year]/
mv specs/[type]/[id]-[name] _archive/[year]/[id]-[name]
```

Add to `.gitignore`:
```gitignore
# Local archives (not committed to version control)
_archive/
```

This keeps the spec on your machine for quick reference but not in the repo.

#### Promotion Checklist

When completing a spec, review:

- [ ] **Review scratch memory:** Identify promotion candidates
- [ ] **Present plan:** Explain promotions to user, get confirmation
- [ ] **Promote content:** Execute approved promotions to project/repo tiers
- [ ] **Commit changes:** Push promoted content to origin
- [ ] **Verify push:** Confirm changes are in remote repository
- [ ] **Clean up:** Delete spec or move to local `_archive/`
- [ ] **Document completion:** Update any tracking systems or project status

#### Anti-Patterns to Avoid

**Don't:**
- Execute promotions without user confirmation
- Promote everything "just in case" - be selective
- Duplicate content across tiers - link instead
- Promote spec-specific details to project tier
- Keep archived specs in version control (git history is enough)
- Delete before pushing promoted content to origin

## Context Inheritance

When working in a spec, AI agents should consider context in priority order, with more specific context overriding general context:

### Context Priority Hierarchy

1. **Spec-level** (Highest Priority)
   - `specs/[spec]/[spec].spec.md` - Functional specification
   - `specs/[spec]/[spec].plan.md` - Implementation plan
   - `specs/[spec]/context/` - Curated context files
   - `specs/[spec]/context/scratch/` - Working memory

2. **Repo-level**
   - `specs/[spec]/repo/[repo-name]/AGENTS.md` or `CLAUDE.md` - Repo instructions
   - `specs/[spec]/repo/[repo-name]/README.md` - Repo documentation
   - Cloned repo's documentation and code

3. **Project-level**
   - `architecture/` - Architecture documentation, ADRs, patterns
   - `requirements/` - PRDs, test strategies
   - `project/` - Product briefs, project charters
   - Root-level `AGENTS.md` - Meta-repo instructions

4. **Org-level** (Lowest Priority)
   - `org/standards/` - Enterprise standards
   - `org/patterns/` - Shared architectural patterns
   - `org/templates/` - Organization-wide templates

### How to Apply Context Priority

**Rule:** More specific context wins. When contexts conflict, prefer the narrower scope.

**Example 1: Coding Standards Conflict**

- **Org-level** says: "Use 2-space indentation for all code"
- **Repo-level** says: "This Python repo uses 4-space indentation (PEP 8)"
- **Action:** Use 4-space indentation (repo-level wins)

**Example 2: Architecture Decision**

- **Project-level** says: "We use PostgreSQL for all services"
- **Spec-level** says: "This specific service needs Redis for caching"
- **Action:** Use Redis for this service (spec-level wins, adds to project context)

**Example 3: API Design Pattern**

- **Org-level** says: "REST APIs must use snake_case"
- **Project-level** says: "Our API uses camelCase for consistency with frontend"
- **Action:** Use camelCase (project-level wins)

### Reading Order for AI Agents

When starting work in a spec, read context in this order:

**Phase 1: Understand the Task (Spec-level)**
1. Read `[spec].spec.md` to understand what needs to be done
2. Read `[spec].plan.md` to understand the approach
3. Check `context/` for curated reference materials
4. Review `context/scratch/notes.md` if continuing previous work

**Phase 2: Understand the Repositories (Repo-level)**
1. Read `repo/[name]/AGENTS.md` for repo-specific guidance
2. Read `repo/[name]/README.md` for setup and structure
3. Review relevant code and documentation in cloned repos

**Phase 3: Understand the Project (Project-level)**
1. Check `architecture/` for architectural constraints and patterns
2. Review relevant PRDs in `requirements/` for feature context
3. Read `project/` docs for business context and goals
4. Review root `AGENTS.md` for meta-repo conventions

**Phase 4: Understand Enterprise Context (Org-level, if exists)**
1. Check `org/standards/` for mandatory enterprise standards
2. Review `org/patterns/` for recommended approaches

### Practical Scenarios

**Scenario 1: Implementing a New API Endpoint**

You're working in `specs/feature/42-user-profile/`:

```
1. Read specs/feature/42-user-profile/42-user-profile.spec.md
   → Learn: Need to add GET /users/:id/profile endpoint

2. Read specs/feature/42-user-profile/42-user-profile.plan.md
   → Learn: Modifying backend-api repo, will add to Express router

3. Read specs/feature/42-user-profile/repo/backend-api/AGENTS.md
   → Learn: Repo uses TypeScript, tRPC (not REST), strict error handling patterns

4. Check architecture/patterns/api-design.md (project-level)
   → Learn: Project uses consistent error codes, requires OpenAPI docs

5. Apply context in priority:
   - Use tRPC (repo-level overrides spec's REST assumption)
   - Follow repo's TypeScript patterns (repo-level)
   - Use project's error code conventions (project-level)
   - Document endpoint (project-level requirement)
```

**Scenario 2: Choosing a Testing Approach**

You're working in `specs/chore/15-add-tests/`:

```
1. Read specs/chore/15-add-tests/15-add-tests.plan.md
   → Learn: Need integration tests for payment flow

2. Read specs/chore/15-add-tests/repo/payment-service/AGENTS.md
   → Learn: Uses Jest, has existing test patterns, mocks Stripe API

3. Check requirements/prd-payments.md (project-level)
   → Learn: Must test failure scenarios, refunds, currency handling

4. Check org/standards/testing-standards.md (if exists)
   → Learn: Enterprise requires test coverage >80%, security test cases

5. Apply context:
   - Use Jest with existing patterns (repo-level)
   - Test scenarios from PRD (project-level)
   - Ensure >80% coverage (org-level)
   - Follow existing mock patterns (repo-level wins over generic org standards)
```

**Scenario 3: Resolving Ambiguity**

When spec is unclear, consult higher context tiers:

```
Spec says: "Add proper error handling"

1. Check repo/[name]/AGENTS.md
   → Find: Existing error handling patterns, custom error classes

2. Check architecture/patterns/error-handling.md
   → Find: Project-wide error codes, logging conventions

3. Apply both:
   - Use repo's error classes (repo-specific implementation)
   - Follow project error codes (project-wide consistency)
   - Match repo's existing patterns (repo-level guides "how")
```

### When Context Tiers Collaborate

Not all context relationships are conflicts. Often they complement:

- **Org** defines "must use OAuth2" → **Project** specifies "via Auth0" → **Repo** shows "here's our auth middleware" → **Spec** says "add auth to this endpoint"
- **Project** says "we use microservices" → **Repo** is one microservice → **Spec** adds a feature to that microservice
- **Org** provides "API design guide" → **Project** adapts it → **Repo** implements it → **Spec** follows established patterns

**Principle:** Each tier adds specificity. Conflicts are resolved by preferring narrower scope.

## See Also

- `../architecture/README.md` - Architecture context conventions
- `../project/README.md` - Project context conventions
- `../requirements/README.md` - Requirements context conventions
- `../AGENTS.md` - AI assistant instructions for this meta-repo
