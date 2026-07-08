# Execution Plan: bug/straddle-default

## Summary
Ensure the hand parser's system prompt instructs that `metadata.straddle` defaults
to `false` when no straddle is mentioned. Single-repo, single-file change.

## Repos
- **lolfold-api** (only repo)

## Dependency order
None — single repo.

## Per-repo tasks: lolfold-api

Target file: `src/services/hand.ts`

1. Locate the parser system prompt and the rule describing `metadata.straddle`.
2. Add an explicit instruction: `metadata.straddle` defaults to `false` when no
   straddle is mentioned in the input.
3. TDD: add a test that pins the prompt contains this instruction.
4. Verify no behavioral change for hands that explicitly mention a straddle.

## Acceptance criteria (from SPEC.md)
- System prompt states straddle defaults to `false` when not mentioned.
- A test pins that the prompt contains this instruction.
- No change to hands that explicitly mention a straddle.

## Verification gates (lolfold-api build config)
- install: `npm ci`
- build: `npm run build`
- test: `npm test`
- typecheck: `npx tsc --noEmit`

## Integration points
None — no cross-repo contracts.

## Quality gate
`minimal` — spec-review, plan-review, spec-complete all SKIP. Only pr-review pauses.
