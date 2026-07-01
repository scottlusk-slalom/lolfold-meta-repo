# META-REPO-GUIDE.md

This is the day-to-day reference for the spec lifecycle in the agent harness platform. Use this as your primary guide for creating, managing, and completing specs across multiple repositories.

## 1. Creating a Spec

### AI Command (Recommended)

```bash
/generate-spec <id> "<brief>" --type feature|bug|chore|design|planning
```

**Flags:**
- `--scaffold-only` — Create directory structure without running analysis
- `--skip-curator` — Skip context curation step
- `--skip-analyzer` — Skip analysis generation
- `--dry-run` — Preview what would be created without writing files

**Example:**
```bash
/generate-spec auth-001 "Implement OAuth2 integration" --type feature
```

### Manual Steps (If Not Using AI)

1. Create directory structure:
   ```bash
   mkdir -p specs/<type>/<id>/{context/scratch,repo}
   ```

2. Copy templates from `docs/templates/`

3. Initialize status files

### Resulting Directory Layout

```
specs/<type>/<id>/
├── <id>.spec.md        (status: specified)
├── <id>.plan.md        (status: not_started)
├── status.md
├── context/
│   ├── CONTEXT.md
│   ├── *-analysis.md
│   ├── decisions.md
│   ├── requirements.md
│   └── scratch/        (gitignored)
└── repo/               (gitignored)
```

## 2. Standalone Spec Fast Path

For simple, single-feature specs that don't require Jira tracking:

```bash
# 1. Generate spec
/generate-spec <id> "<brief>" --type feature
# Result: spec (status: specified) + plan (status: not_started)

# 2. Approve the plan
/approve <id>
# Result: spec → planned, plan → approved

# 3. Execute across repositories
/multi-repo-loop <id> --gates minimal
# Result: per-repo execution → spec → executed → submitted

# 4. Finalize and archive
/finalize-spec <id>
# Result: archive + retrospective → spec → archived
```

## 3. Optional Jira Tracking

Use these commands when your spec needs to integrate with Jira:

### Push Spec to Jira
```bash
/push-to-jira <spec-id> --epic <EPIC-KEY>
```
Creates Jira issues from spec tasks and links them to the epic.

### Sync Status to Jira
```bash
/sync-jira [spec-path]
```
Posts remote links and gate status as comments to linked Jira issues.

### Create Specs from Jira
```bash
/jira-to-specs <EPIC-KEY|JQL>
```
Scaffolds specs from existing Jira stories. Stories with blocking questions will have plan status set to `blocked`.

## 4. Working Within a Spec

### Repository Setup

Clone target repositories into the spec's repo directory (gitignored):

```bash
cd specs/<type>/<id>/repo/
git clone <repo-url> <repo-name>
cd <repo-name>
git checkout -b feat/<spec-id>
```

Each repository gets its own worktree on a `feat/<spec-id>` branch for isolation.

### Context Curation

Store all context in the `context/` directory:

- **CONTEXT.md** — Manifest of all context files (reference by path, never copy file bodies)
- **requirements.md** — Requirements analysis
- **decisions.md** — Architectural decisions made during spec
- ***-analysis.md** — Various analysis outputs
- **scratch/** — Volatile notes, temporary files (gitignored)

**Important:** Reference files by path in CONTEXT.md. Never duplicate file bodies between tiers.

### Cross-Repo Work

When working across multiple repositories:
1. Each repo maintains its own branch: `feat/<spec-id>`
2. Context stays centralized in `specs/<type>/<id>/context/`
3. Track progress in `status.md` and `project/gate-status.yaml`

### Status Tracking

#### Spec Status Lifecycle
```
specified → planned → executed → submitted → archived
```

#### Plan Status Values
```
not_started | approved | in_progress | completed | on_hold | blocked
```

**Commands that set plan status:**
- `not_started` — `/generate-spec` (scaffold)
- `blocked` — `/jira-to-specs` (when blocking questions exist)
- `approved` — `/approve`
- `in_progress`, `completed`, `on_hold` — Manual updates or workflow commands

## 5. Completing a Spec

When a spec is complete and PRs are submitted, finalize it:

```bash
/finalize-spec <id>
```

### Finalization Process

The command performs these steps:

1. **Verify Gate Status** — Ensures gate is `submitted`
2. **Run Retrospective** — Analyzes scratch files, git diffs, and PR feedback
3. **Promote Durable Learnings** — Moves reusable content to target directories
4. **Archive Spec** — Executes `git mv` to `specs/archive/<type>/<id>/`
5. **Update Gate** — Sets final gate status to `archived`

### Context Promotion Targets

| Source Content | Target Directory |
|----------------|------------------|
| Architectural decisions | `architecture/adr/` |
| Reusable patterns | `architecture/patterns/` |
| API contracts | `architecture/contracts/` |
| Repo-specific references | `project/references/` |
| Everything else | Delete |

**All promotions require user confirmation before writing.**

## 6. Customizing for Your Project

### Essential Customization Points

#### AGENTS.md
Fill in the Project Overview section with:
- Project name and purpose
- Tech stack
- Team structure
- Communication channels

#### project/project-repositories.yaml
Register all target repositories:
```yaml
repositories:
  - name: backend-api
    path: specs/*/repo/backend-api
    remote: git@github.com:org/backend-api.git
  - name: frontend-app
    path: specs/*/repo/frontend-app
    remote: git@github.com:org/frontend-app.git
```

#### docs/templates/
Adapt templates to your stack:
- `spec-template.md` — Spec structure
- `plan-template.md` — Plan format
- `context-template.md` — Context manifest
- `pr-template.md` — Pull request template

#### .claude/commands/
All 23 commands are customizable:
- `/generate-spec`, `/approve`, `/finalize-spec`
- `/push-to-jira`, `/sync-jira`, `/jira-to-specs`
- `/multi-repo-loop`
- And more...

## 7. Common Workflows

### Feature Development
```bash
/generate-spec feature-123 "Add user profile page" --type feature
# Review and refine spec
/approve feature-123
/multi-repo-loop feature-123
# Review PRs, get approvals
/finalize-spec feature-123
```

### Bug Fix
```bash
/generate-spec bug-456 "Fix login timeout issue" --type bug
/approve bug-456
# Implement fix
/finalize-spec bug-456
```

### Jira-Tracked Epic
```bash
/jira-to-specs EPIC-789
# Generates multiple specs from epic stories
# Work through each spec
/push-to-jira spec-001 --epic EPIC-789
/sync-jira specs/feature/spec-001
```

### Design Spike
```bash
/generate-spec design-999 "Evaluate caching strategies" --type design
# Research and document findings in context/
/finalize-spec design-999
# Promotes decisions to architecture/adr/
```

## 8. Key Constraints

- **No company/product/vendor names** — Keep specs generic and reusable
- **Spec status lifecycle** — `specified → planned → executed → submitted → archived`
- **Plan status** — `not_started | approved | in_progress | completed | on_hold | blocked`
- **All promotions require user confirmation** — Never auto-promote without approval
- **Never copy file body between tiers** — Always reference by path in CONTEXT.md
- **Scratch is ephemeral** — `context/scratch/` is gitignored for volatile notes only
- **Repo directories are gitignored** — `repo/` never enters version control

## 9. Troubleshooting

### Spec won't finalize
- Check gate status: `cat specs/<type>/<id>/status.md`
- Ensure all PRs are submitted
- Verify no blocking issues in `project/gate-status.yaml`

### Context too large
- Use scratch/ for temporary files
- Reference files by path, don't duplicate bodies
- Archive old analysis files

### Cross-repo conflicts
- Each repo maintains independent `feat/<spec-id>` branch
- Resolve conflicts per-repo before creating PRs
- Use spec context/ directory for coordination notes

### Jira sync issues
- Verify Jira credentials configured
- Check epic key format (PROJECT-123)
- Ensure spec has remote link metadata

## 10. Next Steps

After creating your first spec:

1. Review `AGENTS.md` for the full system architecture
2. Customize templates in `docs/templates/`
3. Configure your repositories in `project/project-repositories.yaml`
4. Set up Jira integration if needed
5. Run through the Fast Path workflow with a test spec

For detailed technical guidance, see:
- `AGENTS.md` — System architecture and AI agent instructions
- `SPEC-LIFECYCLE.md` — Detailed status transitions and validations
- `docs/` — Additional documentation and references
