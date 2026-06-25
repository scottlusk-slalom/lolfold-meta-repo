# /review-impl

Adversarial review of implementation before PR submission. Hard gate between execution and submission.

## Usage
/review-impl [--spec-dir <path>]

## Behavior

1. **Load context**:
   - `_working/<key>/spec.md` — original spec with ACs
   - `_working/<key>/impl-plan.md` — planned vs actual
   - `_working/<key>/execution-summary.md` — execution report
   - Git diff of all changes on the feature branch

2. **Invoke reviewer** (`.claude/agents/implementation-reviewer.md`):
   - Provide full diff, spec, and execution summary
   - Reviewer operates with adversarial mindset

3. **Review dimensions**:
   - **Correctness**: Does the implementation satisfy ALL acceptance criteria?
   - **Test coverage**: Is every AC covered by at least one test? Are edge cases tested?
   - **Regressions**: Any existing functionality broken?
   - **Security**: OWASP top-10 surface area introduced?
   - **Conventions**: Does code follow project patterns from CLAUDE.md?
   - **Scope creep**: Was anything implemented beyond what the spec requires?
   - **TDD compliance**: Evidence of test-first (test commits precede impl commits)?

4. **Verdict** (exactly one of):
   - `PASS` — implementation is correct, submit PR
   - `PASS_WITH_NOTES` — minor issues noted, address then submit (no re-review needed)
   - `FAIL` — significant issues, must fix and re-run `/review-impl`

5. **On FAIL**:
   - List specific issues with file:line references
   - Categorize: `must-fix` vs `should-fix`
   - Return to `/execute-impl` to address `must-fix` items
   - Re-run `/review-impl` after fixes

6. **On PASS_WITH_NOTES**:
   - List notes with file:line references
   - Address notes (commit fixes)
   - Proceed to `/submit-pr` without re-review

## Output
Written to `_working/<key>/review-result.md`:
```markdown
# Review Result — <spec-key>

## Verdict: PASS | PASS_WITH_NOTES | FAIL

## Findings
### Must-Fix (FAIL only)
- [ ] <file:line> — <issue>

### Should-Fix
- [ ] <file:line> — <issue>

### Notes
- <observation>

## AC Coverage
| AC | Covered By | Status |
|----|-----------|--------|
| AC-1 | test-file.spec.ts:L12 | ✓ |
```

## Reads
- `_working/<key>/spec.md`
- `_working/<key>/impl-plan.md`
- `_working/<key>/execution-summary.md`
- Git diff (feature branch vs base)
- `CLAUDE.md`

## Writes
- `_working/<key>/review-result.md`

## Delegates To
- `.claude/agents/implementation-reviewer.md`
