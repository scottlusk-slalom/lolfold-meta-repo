# Orchestrator State — bug/replayer-display-fixes (new-model, branch control surface)

## Mode
- Cloud. Runtime ARN: arn:aws:bedrock-agentcore:us-west-2:446490546198:runtime/lolfold_harness_subagent-a8i1REH7Bj
- Control surface: metarepo spec PR #14 (branch spec/bug/replayer-display-fixes)

## Lifecycle position
- Authoritative status file: replayer-display-fixes.spec.md → `specified` (fresh kickoff)
- gate-status.yaml: NO entry for this key yet
- quality_gate: standard → spec-review skip, plan-review PAUSE, pr-review PAUSE, spec-complete skip
- Current step: plan-review gate applied to PR #14; idle awaiting human `Decision: approved`

## Stale-artifact note (do NOT act on these)
- main has old-protocol cruft: spec.yaml(status=submitted), old scratch claiming phantom PR #15,
  CLOSED status issue #11. All irrelevant to this branch-based control surface.
- Verified: NO lolfold-frontend companion PR (any state), NO agent/bug/replayer-display-fixes* branch.
  Latest FE replayer work = PR#14 "Pokerscope overhaul" (2026-07-01), unrelated.
- Posted halt+correction comments on PR #14.

## Repos & sequence
- lolfold-frontend (only repo, no depends_on). Per-repo status: NOT dispatched.
  - branch to be created by sub-agent: agent/bug/replayer-display-fixes
  - build: install=npm ci, build=npm run build, test=npm run test:run, typecheck=npx tsc -b --noEmit

## Duplicate guard (checked clean at kickoff)
- No agent/* branches on lolfold-frontend. No open/closed target PRs for this key.
- No orchestrator-pause PRs open on metarepo. Labels confirmed present on metarepo.

## Next action on wake
- plan-review approved (human `Decision: approved` on #14) → run /approve replayer-display-fixes
  (sets status=planned, seeds gate-status via /update-gate planned). Then dispatch lolfold-frontend:
  one sub-agent, /multi-repo-loop replayer-display-fixes --repos lolfold-frontend --gates standard.
  Ensure sub-agent-complete label exists (it does). Record session id here, idle.
- plan-review rejected/changes_requested → surface, do not advance.
