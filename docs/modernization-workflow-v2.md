---
type: playbook
status: active
---

# Modernization Workflow v2

Full end-to-end execution workflow with all commands, agents, and phase gates.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    META-REPO (this repo)                  │
│  Orchestration layer — no product code lives here        │
│                                                          │
│  specs/         → spec lifecycle + worktrees             │
│  project/       → registry, plans, gate tracking         │
│  architecture/  → decisions, patterns, legacy analysis   │
│  playbooks/     → agent execution instructions           │
│  org/           → platform standards cache               │
└─────────────────────────────────────────────────────────┘
           │                              │
           ▼                              ▼
┌────────────────────┐      ┌────────────────────┐
│  repos/<name>/     │      │  specs/.../repo/   │
│  Reference clone   │      │  Feature worktree  │
│  (stays on main)   │      │  (feat/<key>)      │
└────────────────────┘      └────────────────────┘
```

## Phase Command Table

| Phase | Name | Commands |
|-------|------|----------|
| 0 | Setup | `/register-repo`, `/scaffold-repo`, `/init-repo` |
| 1 | Discovery | `/onboard-legacy-repo`, `/fetch-confluence` |
| 2 | Planning | `/plan-modernization`, `/generate-engineering-plan` |
| 3 | Decomposition | `/decompose-phase`, `/approve --stage slices` |
| 4 | Spec Generation | `/generate-spec`, `/jira-to-specs` |
| 5 | Execution | `/multi-repo-aos-loop`, `/dispatch-batch` |
| 6 | Completion | `/finalize-spec`, `/retrospective` |
| 7 | Decommission | `/promote-repo archived`, `/archive-spec` |

## Repo Lifecycle Mini-Flow

```
/register-repo (proposed)
    → /promote-repo planned
    → /scaffold-repo (creates from template)
    → /promote-repo active
```

## `/multi-repo-aos-loop` Execution Sequence (12 steps)

1. Select repos from `project/project-repositories.yaml` (`when_to_use` / `selection_guidelines`)
2. `setup-worktree.sh` — git worktree at `specs/<type>/<key>/repo/<repo>/`
3. `stage-context.sh` — copy spec + analysis into `_working/<key>/`
4. `check-deps.sh` — verify local services reachable
5. `/aos-plan` — generate implementation plan (retries: 0)
6. `/aos-execute` — TDD implementation (retries: 3)
7. `check-mock-violations.sh` — enforce integration constraints
8. `/aos-submit-pr` — open pull request (retries: 1)
9. `/pr-review` — review the PR
10. `persist-plan.sh` — copy plan to tracked `plans/` dir
11. `/update-gate <key> executed`
12. `/update-gate <key> submitted --evidence <pr-url>`

## `/dispatch-batch` Pipeline

```
Phase 1: Context Analysis    → context-curator + legacy-analyzer
Phase 2: Decomposition       → slice-decomposer
Phase 3: Approval Gate       → require slice map status: approved
Phase 4: Feature Spec Gen    → /generate-spec per slice
Phase 5: Execution           → /multi-repo-aos-loop per slice (step-ordered)
Phase 6: Tracking            → gate updates + tracking commit
```

## Command Reference

### Spec Lifecycle
| Command | Input | Output |
|---------|-------|--------|
| `/generate-spec` | brief + type | spec.md + plan.md (specified) |
| `/approve` | spec-id | status: planned, plan: approved |
| `/update-gate` | spec-id + status | gate-status.yaml entry |
| `/finalize-spec` | spec-id | archived + learnings promoted |
| `/list-specs` | — | formatted table |

### Planning & Orchestration
| Command | Input | Output |
|---------|-------|--------|
| `/plan-modernization` | legacy docs | executive-readout + engineering-plan |
| `/generate-engineering-plan` | scope | scoped plan with code citations |
| `/decompose-phase` | phase | slice map (sizing-validated) |
| `/dispatch-batch` | planning-id + steps | executed feature specs |
| `/multi-repo-aos-loop` | spec-key + gates | PRs per repo |

### Repo Management
| Command | Input | Output |
|---------|-------|--------|
| `/register-repo` | name or URL | registry entry (proposed/active) |
| `/promote-repo` | name + target | lifecycle transition |
| `/scaffold-repo` | name + template | new repo from GP template |
| `/init-repo` | path | loop-ready config |
| `/repo-status` | filter or path | dashboard or readiness check |

## Key Principles

- **No product code in meta-repo** — only specs, plans, and orchestration
- **Feature work in worktrees** — `specs/.../repo/<name>/` on `feat/<key>`
- **`repos/<name>/` stays on main** — reference clones only
- **GP compliance is a gate** — validated before loop dispatch
- **Worktree path convention**: `specs/<type>/<key>/repo/<repo-name>/`
