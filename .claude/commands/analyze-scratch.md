# Analyze Scratch Memory

Review scratch memory and git changes for valuable insights that should be promoted to permanent context.

## Instructions

1. Determine the spec directory:
   - Check if the current working directory is within a spec directory
   - If not, ask the user which spec to analyze (use /list-specs to show options)

2. Analyze git changes related to this spec:
   - Check git status and recent commits for files modified during spec work
   - Look for patterns in what was changed (new features, refactorings, docs, etc.)
   - Identify files that were frequently modified together
   - Note any architectural decisions or patterns visible in the diffs
   - Look for:
     - New patterns or conventions introduced in code
     - Dependencies added or removed
     - API contracts or interfaces created/modified
     - Database schema changes
     - Configuration changes
   - These changes may contain valuable context to capture in documentation

3. Read all files in the spec's `context/scratch/` directory:
   - Check both `references/` and `transcripts/` subdirectories
   - Note file types, sizes, and last modified dates

4. For git changes, identify documentation opportunities:
   - Architectural decisions embedded in code changes
     → Suggest: Document in `architecture/` (C4 diagrams, ADRs)
   - New patterns or conventions introduced
     → Suggest: Add to project-level context or style guides
   - Dependencies added or removed
     → Suggest: Update project documentation
   - API contracts or interfaces created/modified
     → Suggest: Document in `architecture/` or `requirements/`

5. For each scratch file or group of related files:
   - Summarize the content (what information does it contain?)
   - Assess value: Is this information still relevant? Is it reference material or temporary notes?
   - Suggest promotion actions:
     - **Keep in scratch**: Temporary, task-specific notes
     - **Promote to spec context/**: Valuable reference material for this spec
     - **Promote to project-level**: Insights valuable across multiple specs
     - **Delete**: No longer relevant or redundant

6. Present findings in a structured format:
   ```
   ## Scratch Memory Analysis

   ### Git Changes Analysis
   - 15 files modified across 8 commits
   - New authentication middleware pattern introduced
     → Suggest: Document in `architecture/00-01-02-auth-middleware.md`
   - Added 3 new dependencies (jwt, bcrypt, passport)
     → Suggest: Update project dependencies documentation
   - Created new API endpoints for user management
     → Suggest: Document in `requirements/` or API documentation

   ### High-Value Items (Recommend Promotion)
   - `references/api-docs.md` (15KB) - Comprehensive API documentation
     → Suggest: Promote to `context/` for this spec
   - `references/architecture-decisions.md` (8KB) - Design decisions
     → Suggest: Promote to `architecture/` as ADR

   ### Temporary Notes (Can Archive)
   - `transcripts/debug-session-2025-12-15.md` (3KB) - Debugging notes
     → Suggest: Delete (issue resolved, no longer relevant)

   ### Uncertain (Need User Input)
   - `references/performance-data.csv` (45KB) - Performance test results
     → Question: Should this be kept for future reference?
   ```

7. Ask the user which actions to take:
   - Offer to execute the suggested promotions/deletions
   - Allow user to override suggestions
   - Remind about the memory promotion routine from THREE_TIER_MEMORY.md

8. If user approves promotions:
   - Copy files to appropriate locations (context/, architecture/, requirements/, etc.)
   - Create new architecture documentation based on code changes if needed
   - Update any YAML front matter or documentation as needed
   - Delete or archive scratch files as directed

See `docs/THREE_TIER_MEMORY.md` for the complete memory promotion routine.
