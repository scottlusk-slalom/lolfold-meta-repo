# Execute Spec

Execute an approved spec through implementation, validation, review, and PR submission.

## Lifecycle Stage

`execute-spec` transitions status through **executed** → **submitted**.

## Instructions

### Pre-flight: Approval Gate Check

1. Read the spec's `status.md`
2. **HARD GATE**: If `approval_gate` is not `approved`, STOP and inform the user:
   ```
   ✗ Spec not approved for execution.
   Current status: {lifecycle}
   Approval gate: {approval_gate}
   
   Run /approve-spec first.
   ```
3. If approved, proceed to execution stages

---

### Stage 1: Create Isolated Git Worktrees

1. Identify target repositories from the spec/plan
2. For each repository:
   - Ensure repo is cloned in `specs/{type}/{name}/repo/`
   - Create branch: `spec/{type}/{name}`
   - Create worktree: `specs/{type}/{name}/repo/{repo-name}-worktree`
   - Install dependencies in worktree
   - Verify build passes on clean worktree

3. Update status:
   ```yaml
   lifecycle: executing
   stage: worktree-setup
   ```

---

### Stage 2: Implement (RED/GREEN/Refactor)

For each implementation task in the plan, in order:

#### RED Phase
1. Write tests that encode the relevant success criteria
2. Run tests — they MUST fail (if they pass, the criterion is already met or the test is wrong)
3. Commit: `test: add failing tests for {task description}`

#### GREEN Phase
1. Write the minimal implementation to make tests pass
2. Run tests — they MUST pass
3. Commit: `feat: implement {task description}`

#### Refactor Phase
1. Clean up code while keeping all tests green
2. Run tests — confirm still passing
3. Commit: `refactor: clean up {task description}`

Update status after each task:
```yaml
stage: implementing
tasks_completed: {n}/{total}
```

If tests fail unexpectedly, invoke the troubleshooter agent (`agents/troubleshooter.md`).

---

### Stage 3: Validate Coverage and Risk Assessment

1. **Test Coverage**:
   - Run full test suite in worktree
   - Verify coverage has not decreased
   - Confirm every success criterion from the spec has corresponding test(s)
   - Report any uncovered criteria

2. **Risk Assessment**:
   - Calculate change scope (files changed, lines added/removed)
   - Identify high-risk areas (auth, payments, data migrations)
   - Check for breaking changes to public APIs
   - Verify no secrets or credentials in diff

3. Update status:
   ```yaml
   stage: validation
   coverage: {pass/fail}
   risk_level: {low/medium/high}
   ```

---

### Stage 4: Adversarial Review

Invoke the reviewer agent (`agents/reviewer.md`):

1. Review all changes against spec success criteria
2. Perform security analysis
3. Check edge cases and error handling
4. Assess performance impact
5. Produce review report

**Gate logic**:
- **PASS**: Proceed to PR
- **PASS_WITH_NOTES**: Present notes to user, proceed if they accept
- **FAIL**: Present critical findings, fix issues, re-validate (loop back to stage 3)

Update status:
```yaml
stage: review
review_verdict: {PASS/PASS_WITH_NOTES/FAIL}
```

---

### Stage 5: Submit PR

1. Push branch to remote for each affected repository
2. Create PR with:
   - Title: `{spec-type}: {spec-name}`
   - Body:
     ```markdown
     ## Spec
     Implements: specs/{type}/{name}
     
     ## Summary
     {Brief description from spec problem statement}
     
     ## Changes
     {List of key changes from the plan}
     
     ## Test Coverage
     - All success criteria have corresponding tests
     - Coverage: {coverage metrics}
     
     ## Risk Assessment
     - Risk level: {low/medium/high}
     - {Key risks and mitigations}
     
     ## Review
     - Adversarial review: {verdict}
     - {Notable findings addressed}
     ```

3. Update status:
   ```yaml
   lifecycle: submitted
   stage: pr-submitted
   pr_url: {url}
   ```

4. Confirm:
   ```
   ✓ PR submitted: {pr_url}
   
   Spec: specs/{type}/{name}
   Status: submitted
   Review verdict: {verdict}
   
   Run /archive-spec after PR is merged.
   ```

## Agent References

- Uses: `agents/executor.md` for stages 1-3
- Uses: `agents/troubleshooter.md` for failure diagnosis
- Uses: `agents/reviewer.md` for stage 4
