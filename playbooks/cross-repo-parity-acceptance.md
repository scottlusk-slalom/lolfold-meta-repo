---
name: cross-repo-parity-acceptance
applies_when:
  spec_section: "## Acceptance Criteria"
  ac_contains_any:
    - "behaves identically"
    - "same behavior"
    - "parity"
    - "persists across"
skip_when:
  spec_tags_any: [single-repo]
requires:
  - test-runner
injects_into: execute
---

# Cross-Repo Parity Acceptance

Test-coverage rules for "behaves identically across A and B" acceptance criteria.

## Rule 1: Full Path Coverage for Parity ACs

> A "behaves identically for A and B" AC needs a test on **every path**.

### Canonical Failure
A sort-control component was implemented for both entity types. Tests covered the default sort and one custom sort, but missed the iteration where sort order resets on filter change. Entity B had a bug where the sort parameter was dropped after filtering — only caught in manual QA because the test only verified the initial sort state.

### Required Tests
For any "behaves identically" AC:
- Test the feature for entity A (all paths)
- Test the **same paths** for entity B
- Test edge cases: state transitions, resets, concurrent operations
- Test that A and B produce the same output given the same input

## Rule 2: Persistence Test for "Persists Across X" ACs

> A "persists across X" AC needs a test that **performs X**.

### Canonical Failure
A user preference was stored in local state but the AC said "persists across page navigation." The test verified the preference was set but never navigated away and back. The implementation used component state instead of a persistent store — only caught when a user reported the preference resetting.

### Required Tests
For any "persists across" AC:
- Set the state
- Perform the interrupting action (navigate, refresh, close/reopen)
- Verify the state survived

## How to Apply

1. Scan all ACs in the spec for parity/persistence language
2. For each match, write the exhaustive test set described above
3. Run tests for BOTH entities/paths — not just one
4. If tests pass for A but fail for B, that's the bug the AC exists to prevent
