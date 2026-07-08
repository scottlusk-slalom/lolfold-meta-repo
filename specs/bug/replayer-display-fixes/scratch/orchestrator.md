# Orchestrator State — bug/replayer-display-fixes

## Lifecycle position
- spec.yaml status: `submitted` (advanced on sub-agent handoff; committed+pushed to main BEFORE pr-review idle)
- Current step: pr-review gate applied to lolfold-frontend PR #15; orchestrator idle awaiting human `Decision:`
- Next gate: **pr-review** decision on #11 → merge|hold|rollback

## Sub-agent handoff (verified)
- PR #15 https://github.com/scottlusk-slalom/lolfold-frontend/pull/15 — OPEN, not draft
- Label on arrival: sub-agent-complete (no sub-agent-failed) → verified OK
- Single repo, no companion PRs. All gates pass (build/test:run/tsc).
- pr-review gate: swapped sub-agent-complete → orchestrator-pause + pr-review; posted review-gate comment to #11 (no wake marker).

## Mode
- Cloud (SUBAGENT_RUNTIME_ARN set)
- Runtime ARN: arn:aws:bedrock-agentcore:us-west-2:446490546198:runtime/lolfold_harness_subagent-a8i1REH7Bj

## Artifacts
- Status issue: #11 (adopted from kickoff; spec-status; "Status: bug/replayer-display-fixes")
- Plan-review gate PR: #12 — MERGED (approved by scottlusk-slalom), branch deleted
- Plan file: specs/bug/replayer-display-fixes/scratch/plan.md (on main)

## Repos & dispatch status
- lolfold-frontend: DISPATCHED (idle, awaiting completion handoff)
  - branch: agent/bug/replayer-display-fixes/lolfold-frontend
  - clone: https://github.com/scottlusk-slalom/lolfold-frontend.git
  - build: install=npm ci, build=npm run build, test=npm run test:run, typecheck=npx tsc -b --noEmit
  - session id: subagent-issue-11-1783544184-----
  - dispatch log: /tmp/dispatch-subagent-issue-11-1783544184-----.log
  - dispatch status comment posted to #11

## Duplicate guard (checked, clean before dispatch)
- No agent/* branches on lolfold-frontend.
- No open target PRs matching spec.
- No other orchestrator-pause PRs.

## Next action on wake
- Wake reason A = sub-agent handoff (completion comment on #11 with wake marker):
  - Verify PR on lolfold-frontend exists. If label sub-agent-failed → HALT, post failure to #11, idle.
  - If sub-agent-complete → set spec.yaml=submitted (commit+push to main FIRST),
    then apply pr-review gate: ensure labels orchestrator-pause + pr-review exist on
    lolfold-frontend, swap sub-agent-complete → orchestrator-pause + pr-review on the PR,
    post review-gate comment to #11 (NO wake marker), idle.
- Wake reason B = human decision on #11 (`Decision: merge|hold|rollback`):
  - Verify commenter human (login not ending [bot]).
  - merge → gh pr merge --squash --delete-branch on target PR; spec.yaml=archived; close #11.
  - hold → idle. rollback → close PR, reset spec=executed, document.

## Notes
- `gh api user` blocked (403 app token); rely on [bot] suffix check on comment author.
- Rule 5: zero commits to main between dispatch and sub-agent PR merge.
- Rule 9: orchestrator NEVER emits the wake marker.
