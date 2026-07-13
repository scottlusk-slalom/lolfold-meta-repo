# Orchestrator scratch — replayer-display-fixes

- **Spec key:** replayer-display-fixes
- **Type:** bug
- **Quality gate:** standard
- **Metarepo:** scottlusk-slalom/lolfold-meta-repo
- **Spec PR:** #16 (branch `spec/bug/replayer-display-fixes`)
- **Spec branch:** spec/bug/replayer-display-fixes

## Gate plan (standard)
- spec-review: skip
- plan-review: PAUSE
- pr-review: PAUSE (per repo)
- spec-complete: skip
- loop `--gates`: standard

## Repo sequence (ordered)
1. lolfold-frontend — status: `pending`

(No `depends_on`; single-repo spec. Cross-repo ordering trivial.)

## Lifecycle position
- Current: `specified` → applying **plan-review** gate on PR #16.
- No `<key>.plan.md` present; per-repo impl plan produced inside /multi-repo-loop.

## Event log
- 2026-07-13: Kickoff wake. PR #16 open, no labels/comments. Spec validated:
  single repo `lolfold-frontend` (exists in registry). Gate=standard → spec-review
  skipped. Applying plan-review pause.

## Session IDs
- (none dispatched yet)
