# /submit-pr

Push branch and open a pull request with spec traceability. Replaces the external `/aos-submit-pr` command.

## Usage
/submit-pr [--spec-dir <path>] [--draft] [--target <branch>]

## Behavior

1. **Pre-flight checks**:
   - Working tree is clean (no uncommitted changes)
   - Review result exists and verdict is `PASS` or `PASS_WITH_NOTES`
   - All tests pass (run test suite one final time)
   - No mock violations (`check-mock-violations.sh`)

2. **Determine target branch**:
   - Use `--target` if provided
   - Else use `integration_branch` from spec frontmatter
   - Else use the repo's default branch

3. **Push branch**:
   - `git push -u origin <branch-name>`

4. **Create PR** via `gh pr create`:
   - Title: `feat(<scope>): <spec title>` (from spec frontmatter)
   - Body structure:
     ```markdown
     ## Summary
     <one-paragraph description from spec>

     ## Spec Reference
     - Spec: `specs/<type>/<key>/<key>.spec.md`
     - Plan: `_working/<key>/impl-plan.md`

     ## Changes
     <bullet list of what was implemented, from execution-summary>

     ## Acceptance Criteria
     | AC | Status | Test |
     |----|--------|------|
     | <from spec> | ✓ | <test file> |

     ## Test Results
     - All tests passing
     - No regressions
     - Review verdict: <PASS|PASS_WITH_NOTES>

     ## Notes
     <any PASS_WITH_NOTES items or risks>
     ```

5. **Record PR URL**:
   - Write to `_working/<key>/pr-url.txt`
   - This URL is used by `/update-gate` as `--evidence`

## Reads
- `_working/<key>/spec.md`
- `_working/<key>/execution-summary.md`
- `_working/<key>/review-result.md`
- `_loop-config.yaml` (for commit format)
- Spec frontmatter (`integration_branch`, title)

## Writes
- `_working/<key>/pr-url.txt`
- Remote: pushes branch
- Remote: creates PR via `gh`

## Retry Policy
1 retry. If PR creation fails on retry, halt and report.

## Pre-requisites
- `gh` CLI authenticated
- Review verdict is PASS or PASS_WITH_NOTES
- Clean working tree
