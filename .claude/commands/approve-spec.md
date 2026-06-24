# Approve Spec

Review and approve a spec for execution. This is the gate between specification and implementation.

## Lifecycle Stage

`approve-spec` transitions status to **planned**.

## Instructions

### Phase 1: Identify Spec

1. Check if the current working directory is within a spec directory
2. If not, list available specs with lifecycle status "specified" and ask which to approve
3. Read the spec's `status.md` to confirm it's in "specified" state

### Phase 2: Review Checklist

Present the following review to the user:

1. **Spec Completeness**:
   - [ ] Problem statement is clear and specific
   - [ ] Success criteria are testable and measurable
   - [ ] Scope boundaries are explicit (in/out)
   - [ ] Dependencies are identified and available
   - [ ] Risks have mitigations

2. **Plan Readiness**:
   - [ ] Implementation tasks are atomic and ordered
   - [ ] Tasks map to success criteria (RED/GREEN coverage)
   - [ ] Affected systems are identified
   - [ ] Testing strategy covers edge cases
   - [ ] Rollback strategy exists for risky changes

3. **Context Readiness**:
   - [ ] Target repositories are identified
   - [ ] Relevant org/project context has been gathered
   - [ ] No conflicting in-progress specs on the same code

### Phase 3: Approval Decision

Ask the user for their decision:
- **Approve** — proceed to planned status
- **Request Changes** — note what needs modification (stays in "specified")
- **Reject** — archive with reason

### Phase 4: Update Status

On approval:

1. Update `status.md`:
   ```yaml
   lifecycle: planned
   approval_gate: approved
   ```
   - Set approver name and date
   - Add any approval notes

2. Update spec front matter status to `active`
3. Update plan front matter status to `not_started`

4. Confirm:
   ```
   ✓ Spec approved: specs/{type}/{name}
   
   Status: planned
   Approved by: {user}
   Date: {today}
   
   Ready for execution. Run /execute-spec to begin implementation.
   ```
