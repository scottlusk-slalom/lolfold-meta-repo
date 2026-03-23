# Project Status: Lolfold POC

**Generated:** 2026-03-23
**Workshop Demo:** Ready (with known issue documented)

## Summary

All 9 specifications executed successfully via autonomous Claude Code agents. Infrastructure deployed, all PRs merged, frontend and API live. One blocking bug prevents AI features from working (Bedrock region routing).

## Completed Work

✅ **Infrastructure (Spec 01)**
- AWS: VPC, RDS PostgreSQL 17.4, ECS Fargate, S3+CloudFront, Bedrock IAM, ECR
- Terraform: All modules deployed, state managed
- GitHub: [lolfold-infra](https://github.com/scottlusk-slalom/lolfold-infra)

✅ **API Foundation (Spec 02)**
- Stack: Node.js 20 + Express + TypeScript + Prisma ORM
- Database: PostgreSQL with Prisma migrations
- Infrastructure: Dockerized, running on ECS Fargate
- GitHub: [lolfold-api](https://github.com/scottlusk-slalom/lolfold-api)

✅ **Frontend Foundation (Spec 03)**
- Stack: Vite + React 19 + TypeScript + Tailwind CSS v4 + React Router v7
- Dark mode: System preference detection
- Deployed: S3 + CloudFront distribution
- GitHub: [lolfold-frontend](https://github.com/scottlusk-slalom/lolfold-frontend)

✅ **Hand Input & Parsing (Spec 04)**
- Shorthand parsing via Bedrock Claude
- Confidence indicators with flagged fields
- Confirm-before-save flow
- **Blocked by:** Spec 11 (Bedrock region bug)

✅ **Player Tracking (Spec 05)**
- Player profiles with merge capability
- AI-generated player summaries
- Note categories with filters
- Player pattern recognition
- **Blocked by:** Spec 11 (Bedrock region bug - summaries only)

✅ **Search & Filtering (Spec 06)**
- Multi-field filters (position, pot type, street, player)
- AI natural language search
- Hand detail modal
- **Blocked by:** Spec 11 (Bedrock region bug - AI search only)

✅ **Hand Replayer (Spec 07)**
- SVG poker table visualization
- Step-through state machine
- Card and board rendering
- Street-by-street progression

✅ **Session Tracking (Spec 08)**
- Session CRUD with venue/stakes/notes
- Active session management (one at a time)
- Auto-association of hands to active session
- Active session banner in app shell

✅ **Group Activity Feed (Spec 09)**
- Activity feed showing hands and notes from all users
- Player name chips link to profiles
- Own activity distinguished from others'
- Integrated into Hands page as third tab mode

## Live URLs

- **Frontend:** https://d1uw756ov4qd1d.cloudfront.net
- **API:** https://d1uw756ov4qd1d.cloudfront.net/api/*
- **API Health:** https://d1uw756ov4qd1d.cloudfront.net/api/health

## Known Issues

### Spec 11: Bedrock Region Routing (High Priority - BLOCKING)

**Impact:** All AI features return 502 errors (hand parsing, AI search, player summaries)

**Status:** Spec created, ready for execution

**Root Cause:** Bedrock SDK routes inference profile `us.anthropic.claude-sonnet-4-6` to us-east-1 instead of us-west-2, causing 403 AccessDenied (IAM policy correctly restricts to us-west-2 only)

**Quick Fix:** Switch to foundation model ID `anthropic.claude-3-5-sonnet-20240620-v1:0`

**See:** `specs/chore/11-bedrock-region-fix/`

## Deferred Work

### Spec 10: Authentication (Low Priority)

**Status:** Spec created, not yet executed

**Scope:** Cognito user pools + Google OAuth, JWT middleware, user context in UI

**Rationale:** Deferred to keep POC scope manageable; access currently restricted by security groups (VPC + operator IP)

**See:** `specs/chore/10-authentication/`

## Repository Structure

```
meta-repo/
├── AGENTS.md              # Prime directives for child agents
├── CLAUDE.md              # Points to AGENTS.md
├── README.md              # Meta-repo overview
├── WORKFLOW.md            # Spec execution workflow
├── STATUS.md              # This file
├── docs/
│   ├── DEPLOYMENT.md      # Infrastructure details
│   └── templates/         # Spec templates
├── org/
│   └── standards.md       # Org-wide conventions (GitHub org, AWS, Terraform)
├── project/
│   ├── product-brief.md   # Product vision
│   └── project-repositories.yaml
├── requirements/
│   └── prd-core.md        # 34 MoSCoW requirements
├── architecture/
│   └── 00-lolfold.md      # C4 system context diagram
└── specs/
    ├── chore/             # Infrastructure & operational work
    │   ├── 01-infra-foundation/      ✅ completed
    │   ├── 02-api-foundation/        ✅ completed
    │   ├── 03-frontend-foundation/   ✅ completed
    │   ├── 10-authentication/        📋 draft (deferred)
    │   └── 11-bedrock-region-fix/    📋 draft (blocking)
    └── feature/           # Product functionality
        ├── 04-hand-input-parsing/    ✅ completed
        ├── 05-player-tracking/       ✅ completed
        ├── 06-search-filtering/      ✅ completed
        ├── 07-hand-replayer/         ✅ completed
        ├── 08-session-tracking/      ✅ completed
        └── 09-group-activity/        ✅ completed
```

## Execution Model Validation

### What Worked

✅ **Background Agent Execution:** `claude -p "prompt" --dangerously-skip-permissions --model opus` executed specs autonomously, created PRs, and exited cleanly

✅ **Prime Directives:** Agents consistently followed rules (no deployment, feature branches only, one spec = one PR, no secrets committed)

✅ **Spec → PR → Merge Workflow:** Clean separation of planning (human+AI writes spec) → execution (agent implements) → review (human/AI merges) → orchestration (main conversation applies infrastructure)

✅ **Three-Tier Memory:** org/ → project/ → repo/ → scratch/ hierarchy kept agents focused and prevented context bloat

✅ **Terraform State:** Infra repo maintained clean terraform state through multiple fixes without needing to destroy/recreate

### What Didn't Work Initially

⚠️ **Over-Engineered Plans:** Initial plan template was too prescriptive (150+ lines with step-by-step instructions). Updated to focus on Approach + Decisions + Milestones (~50-80 lines). This reduced agent thrashing.

⚠️ **Prisma Migration Conflicts:** Agent-created migration only contained ALTER TABLE statements (assuming base schema existed). Required manual intervention to create proper initial migration with CREATE TABLE statements.

⚠️ **Bedrock Model ID:** Spec used future-dated model ID that didn't exist. Should have validated available models before spec creation.

⚠️ **Mixed Content:** Initial deployment had frontend on HTTPS but API on HTTP (ALB). Fixed by adding CloudFront origin for ALB and proxying /api/* path.

### Lessons Learned

1. **Validate External Dependencies:** Check AWS API (available models, RDS versions, etc.) before writing specs
2. **Keep Plans Lean:** Focus on decisions and constraints, not step-by-step instructions—let agents figure out the "how"
3. **Database Migrations Need Care:** Agent workflows struggle with incremental migration history; prefer clean slate for POCs
4. **Test IAM Policies Early:** Region-specific IAM resources can cause subtle runtime failures that only show up in production

## Workshop Demo Script

### Show the Process

1. **Requirements → Specs:** Show how PRD was broken into 9 specs
2. **Spec Execution:** Show an unmodified spec → agent output → PR
3. **Autonomous Chain:** Highlight how specs 01-09 ran sequentially without intervention
4. **Prime Directives:** Show AGENTS.md and how it prevented bad behavior (no secrets, no 0.0.0.0/0 SG rules)

### Show the Product

1. **Live Site:** https://d1uw756ov4qd1d.cloudfront.net
2. **Working Features:**
   - Session creation and management
   - Hand detail viewing and replayer
   - Player profiles with notes
   - Activity feed showing all users' hands
3. **Explain Blocked Features:** Hand parsing, AI search, player summaries (show spec 11 for fix)

### Show the Architecture

1. **Infrastructure Diagram:** C4 context from architecture/00-lolfold.md
2. **AWS Console:**
   - CloudFront distribution
   - ECS service with running task
   - RDS PostgreSQL instance
   - S3 bucket + CloudWatch logs
3. **GitHub Repos:** Show commit history + PR structure (one spec = one PR)

## Next Steps

If continuing the project:

1. **Execute Spec 11:** Fix Bedrock region routing to unblock AI features
2. **User Testing:** Get feedback on hand input shorthand, replayer UX
3. **Execute Spec 10:** Add authentication (Cognito + Google OAuth)
4. **Performance:** Add database indices, API response caching
5. **Observability:** Add Datadog/New Relic, alert on 5xx errors
6. **Cost Optimization:** Review RDS instance size, enable S3 lifecycle policies

## Workshop Demo: Ready ✅

All infrastructure deployed, all core features built, clean spec→PR→merge workflow demonstrated. One blocking bug documented and planned (spec 11). Perfect state for showing the meta-repo framework in action.
