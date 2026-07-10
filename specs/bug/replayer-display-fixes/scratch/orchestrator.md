# Orchestrator State — bug/replayer-display-fixes (cloud, branch control surface)

## Mode
- Cloud. Runtime ARN: arn:aws:bedrock-agentcore:us-west-2:446490546198:runtime/lolfold_harness_subagent-a8i1REH7Bj
- Control surface: metarepo spec PR #14 (branch spec/bug/replayer-display-fixes)

## Lifecycle position (as of 2026-07-10 kickoff re-run)
- Authoritative status file: replayer-display-fixes.spec.md → `specified` (fresh kickoff)
- gate-status.yaml: NO entry for this key yet (will be seeded by /approve → /update-gate planned)
- quality_gate: standard → spec-review SKIP, plan-review PAUSE, pr-review PAUSE, spec-complete SKIP
- CURRENT STEP: plan-review gate APPLIED to PR #14 (labels: orchestrator-pause + plan-review;
  body = review-gate template). IDLE awaiting human `Decision: approved` on PR #14.
- Note: PR #14 labels were confirmed EMPTY before this run — prior session's "gate applied"
  claim was never completed. This run actually applied the labels (verified) + body (via REST API;
  `gh pr edit --body-file`/`--add-label` emit a benign projects-classic GraphQL warning, labels
  still mutate; body set via `gh api PATCH .../pulls/14`).

## Stale-artifact note (do NOT act on these)
- main has old-protocol cruft: spec.yaml(status=submitted), old scratch claiming phantom PR #15,
  CLOSED status issue #11. Irrelevant to this branch-based control surface.
- lolfold-frontend PR #15 existed under old protocol, CLOSED unmerged 2026-07-10, branch deleted.
- Verified clean on CURRENT attempt: NO open lolfold-frontend companion PR for this key,
  NO agent/bug/replayer-display-fixes* branch. Latest FE work = PR#14 "Pokerscope overhaul", unrelated.

## Repos & sequence
- lolfold-frontend (only repo, no depends_on). Per-repo status: NOT dispatched.
  - branch to be created by sub-agent: agent/bug/replayer-display-fixes
  - build: install=npm ci, build=npm run build, test=npm run test:run, typecheck=npx tsc -b --noEmit

## Duplicate guard (checked clean)
- No agent/* branches on lolfold-frontend for this key. No open target PRs.
- Labels present on metarepo: orchestrator-pause, plan-review, pr-review, sub-agent-complete, spec-complete.

## Next action on wake
- plan-review APPROVED (human `Decision: approved` on #14) → run /approve replayer-display-fixes
  (sets status=planned, seeds gate-status via /update-gate planned). Remove orchestrator-pause +
  plan-review labels. Ensure sub-agent-complete label exists (it does). Then dispatch lolfold-frontend:
  ONE sub-agent (serialized), /multi-repo-loop replayer-display-fixes --repos lolfold-frontend --gates standard.
  Record session id here, set per-repo status=dispatched, idle.
- plan-review rejected/changes_requested → surface, do NOT advance.
