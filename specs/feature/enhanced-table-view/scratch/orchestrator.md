# Orchestrator State — feature/enhanced-table-view

## Lifecycle position
- Current spec status: `specified` → advancing to `planned` (pending plan-review gate).
- Mode: **cloud** (SUBAGENT_RUNTIME_ARN set).
- Quality gate: `standard` → spec-review SKIP, plan-review PAUSE, pr-review PAUSE, spec-complete SKIP.

## Artifacts
- Status issue: scottlusk-slalom/lolfold-meta-repo#8
- Metarepo: scottlusk-slalom/lolfold-meta-repo
- Target repo: scottlusk-slalom/lolfold-frontend (single repo)
- Plan: specs/feature/enhanced-table-view/scratch/plan.md

## Dispatched / completed
- No sub-agents dispatched yet. Planning done locally by orchestrator (single-repo, simple).

## Pending decisions
- **plan-review gate (PAUSE):** open. Awaiting human `Decision: approved|rejected|changes_requested`
  on the plan-review PR.
- **OPEN QUESTION** raised in plan: reference screenshot = poker replayer table
  (pokerscope.app/hand/...), but SPEC text says "data table/rows/columns."
  Plan assumes screenshot authoritative (replayer table). Human must confirm.

## Duplicate guard (checked at kickoff)
- No open PRs matching enhanced-table-view.
- No `agent/feature/enhanced-table-view*` branches on lolfold-frontend.
- No prior spec-status issue (created #8 fresh).

## Notes
- Local inspection clone at /tmp/workspace/_inspect/lolfold-frontend (read-only, not committed).
- Component chain: HandDetailPage → HandReplayer (max-w-4xl) → PokerTable (SVG w-full, viewBox 600x440).

## Next action on resume
- Woken by human comment on plan-review PR → parse decision:
  - approved → set spec.yaml status=planned, commit/push, close/merge gate PR, dispatch execution sub-agent for lolfold-frontend.
  - changes_requested/rejected → revise plan or halt per feedback.
