---
type: chore
status: draft
priority: low
created: 2026-03-23
updated: 2026-03-23
tags: ["meta-repo", "framework", "improvement"]
related: []
---

# Meta-Repo Framework Improvements

## Context

These are structural improvements identified during the Lolfold POC build. They should NOT be applied to the Lolfold meta-repo retroactively — it should remain as-is to accurately reflect how the POC was built. Apply these to the meta-repo template/framework for future projects.

## Improvements

### 1. Move Prime Directives to Org Context

**Current:** Prime Directives (never deploy, never commit secrets, no 0.0.0.0/0 SG, one spec = one PR, feature branches only) live in `AGENTS.md`.

**Should be:** `org/standards.md` — these are organizational policies that apply across all projects, not project-specific agent instructions.

**Why:** The three-tier memory model (org → project → repo) exists for this purpose. Org-level rules should live in org context so they automatically carry to new projects without copy-paste. `AGENTS.md` should reference org context but not duplicate it.

**Risk:** Unknown whether child agents would have followed org/standards.md as reliably as AGENTS.md during spec execution. Needs testing with a fresh project.

### 2. Plan Template Was Over-Specified

**Original problem:** Plans were 150+ lines with step-by-step instructions, listing every file and command.

**Fix applied:** Updated template to focus on Approach + Key Decisions + Milestones. Target 50-100 lines.

**For framework:** The updated template (`docs/templates/specname.plan.md`) is already correct. Just ensure it ships as the default in the framework.

### 3. Validate External Dependencies Before Writing Specs

**Problem:** Specs referenced a non-existent Bedrock model ID, an unavailable RDS engine version, and included auth (Cognito) that was later descoped. All required rework.

**For framework:** Add a pre-spec checklist or guidance in the spec template: verify AWS service availability, model access, engine versions, etc. before finalizing specs.
