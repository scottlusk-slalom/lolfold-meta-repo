---
type: reference
status: active
---

# Meta-Repo Workflow Deck

Engineering onboarding deck — 12 slides explaining the meta-repo workflow.

---

## Slide 1: Meta-Repo Directory Map

```
meta-repo/                          ← NO product code here
├── specs/                          ← Spec lifecycle + worktrees
├── project/                        ← Registry, plans, gates
├── architecture/                   ← Decisions, patterns, legacy
├── playbooks/                      ← Agent execution instructions
├── org/                            ← Platform standards
├── repos/<name>/                   ← Reference clones (main branch)
└── .claude/commands/               ← 23 slash commands
```

**Principle**: No product code in the meta-repo. Ever.

---

## Slide 2: Three-Tier Memory

| Priority | Tier | Location | Persistence |
|----------|------|----------|-------------|
| 1 (highest) | Spec | `specs/*/context/` | Committed |
| 2 | Repo | `repos/<name>/` | In cloned repos |
| 3 | Project | `architecture/`, `project/` | Committed |
| 4 (lowest) | Org | `org/` | Committed, 30-day TTL |

Narrower scope always wins on conflict.

---

## Slide 3: Spec Directory Layout

```
specs/feature/<id>/
├── <id>.spec.md          ← frontmatter: type, status, priority
├── <id>.plan.md          ← frontmatter: status, estimated_effort
├── status.md             ← gate tracking
├── context/              ← curated references
│   ├── CONTEXT.md        ← selection manifest
│   └── scratch/          ← volatile (gitignored)
└── repo/                 ← worktrees (gitignored)
```

---

## Slide 4: Spec Lifecycle State Diagram

```
specified → planned → executed → submitted → archived
    │          │          │           │           │
 /generate  /approve  /multi-repo  /update-gate  /finalize
  -spec                -loop        (evidence)    -spec
```

---

## Slide 5: Execution Loop 5-Phase Diagram

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  PLAN    │ →  │ EXECUTE  │ →  │  REVIEW  │ →  │  SUBMIT  │ →  │  GATE    │
│          │    │   (TDD)  │    │ (advers) │    │   (PR)   │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
  impl-plan       RED/GREEN       PASS/FAIL       PR opened      executed →
  generated       Refactor        gate            reviewed       submitted
```

---

## Slide 6: Worktree Layout

```
specs/feature/<init>/<slice>/
└── repo/
    └── <repo-name>/                  ← git worktree on feat/<slice>
        ├── _working/<slice>/         ← staged spec + live plan
        │   ├── spec.md
        │   ├── codebase-analysis.md
        │   └── decisions.md
        └── src/                      ← actual repo code
```

`_working/` is ephemeral — lost on worktree cleanup.
`plans/<repo>.plan.md` is persisted before cleanup.

---

## Slide 7: `/multi-repo-loop` — 11 Steps

1. Select repos (from `when_to_use` in registry)
2. `setup-worktree.sh` → create worktree
3. `stage-context.sh` → populate `_working/`
4. `check-deps.sh` → verify services
5. `/plan-impl` → generate implementation plan
6. `/execute-impl` → TDD (RED/GREEN/Refactor)
7. `check-mock-violations.sh` → integration gate
8. `/review-impl` → adversarial review (PASS/FAIL)
9. `/submit-pr` → push + open PR
10. `persist-plan.sh` → save plan
11. `/update-gate` → advance lifecycle

---

## Slide 8: Integration Constraints

**Mock Detection Pattern:**
- `check-mock-violations.sh` scans new test files
- Looks for `jest.fn|jest.mock|jest.spyOn` + constrained service names
- Constrained services defined in `_working/<key>/constraints.md`
- Violation = gate failure (not retryable)

**Why:** Prevents test mocks from hiding integration failures.

---

## Slide 9: Program Context Template

| Legacy System | New Repo | Stack | Status |
|--------------|----------|-------|--------|
| `<your legacy app>` | `<your new repo>` | `<your stack>` | proposed |

Fill in per engagement:
- Legacy endpoints → `architecture/legacy/service_inventory.md`
- Integration map → `architecture/legacy/integration_map.md`
- Platform requirements → `org/`

---

## Slide 10: Day-to-Day — Single Slice

```bash
/generate-spec my-feature "Add user profile endpoint" --type feature
/approve my-feature
/multi-repo-loop my-feature --gates minimal
/finalize-spec my-feature
```

---

## Slide 11: Day-to-Day — Full Phase

```bash
/plan-modernization
/decompose-phase "Phase 2 - APIs"
/approve phase-2-apis --stage slices
/dispatch-batch phase-2-apis --steps A,B,C --gates standard
```

---

## Slide 12: Critical Constraints

1. **No product code in meta-repo**
2. **`repos/<name>/` stays on default branch** — never commit features there
3. **Feature work in spec worktrees only**
4. **Gate transitions one step forward** (unless `--force`)
5. **Mock violations are not retryable**
6. **Slice sizing limits**: ≤15 files, ≤2 modules, ≤7 ACs, ≤500 LOC
7. **`/update-gate` is the sole writer** of `gate-status.yaml`

---

## Appendix: File Locations

| What | Where |
|------|-------|
| Slash commands | `.claude/commands/*.md` |
| Subagents | `.claude/agents/*.md` |
| Loop scripts | `.claude/commands/scripts/*.sh` |
| Validation scripts | `scripts/*.sh` |
| Reference docs | `.claude/commands/references/` |
| Playbooks | `playbooks/*.md` |
| Gate tracking | `project/gate-status.yaml` |
| Repo registry | `project/project-repositories.yaml` |
| Platform rules | `org/` |
