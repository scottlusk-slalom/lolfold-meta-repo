# Archive Spec

Archive a completed spec with proper memory promotion and cleanup.

## Instructions

1. Determine which spec to archive:
   - Check if the current working directory is within a spec directory
   - If not, ask the user which spec to archive (show completed specs using /list-specs)

2. Verify the spec is ready for archiving:
   - Check the spec status (should be "completed")
   - Confirm all tasks in the plan are marked complete
   - Warn if status is not "completed" and ask for confirmation

3. Run memory promotion analysis:
   - Execute the same analysis as `/analyze-scratch`
   - Identify valuable insights in `context/scratch/`
   - Prompt user to promote important findings to:
     - Spec-level `context/` (if valuable for the spec record)
     - Project-level directories (if valuable across specs)
     - Architecture docs (if containing architectural decisions)

4. Clean up the spec:
   - **Scratch memory**: Ask if user wants to delete entirely (recommended) or keep local archive
   - **Cloned repositories**:
     - Check project/project-repositories.yaml for information about cloned repos
     - Remind user that `repo/` is gitignored
     - Ask if they want to delete cloned repos (recommend yes if changes were pushed)
     - List any uncommitted changes in cloned repos
     - For known repositories, confirm changes were pushed to their configured upstream

5. Update spec metadata:
   - Set spec status to "archived" in YAML front matter
   - Add `archived_date: YYYY-MM-DD` to front matter
   - Update the `updated` field to today's date

6. Create archive summary:
   - Generate a brief summary of what was accomplished
   - Note any promoted context or architectural decisions
   - Add to the spec.md file as a new "## Archive Summary" section

7. Commit the archival:
   - Stage changes to the spec files (metadata updates, promoted context)
   - Create a commit: "chore: archive spec [spec-name]"
   - Remind user to push if appropriate

8. Provide archive confirmation:
   ```
   ✓ Spec archived: specs/feature/123-user-auth

   Summary:
   - Status updated to "archived"
   - 2 files promoted from scratch to context/
   - 1 architectural decision promoted to architecture/
   - Scratch memory cleaned (3 files deleted)
   - Cloned repos deleted (2 repos, all changes pushed)

   Commit created: "chore: archive spec 123-user-auth"
   ```

See `docs/THREE_TIER_MEMORY.md` for the complete memory promotion routine.
