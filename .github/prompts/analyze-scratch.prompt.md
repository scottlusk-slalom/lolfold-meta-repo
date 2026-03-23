---
description: Review scratch memory and git changes for valuable insights that should be promoted to permanent context
name: analyze-scratch
argument-hint: spec-name
agent: agent
---

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

   ### Git Changes
   [Summary of recent changes with promotion suggestions]

   ### Scratch Files
   - File: context/scratch/references/api-docs.md (15 KB, modified 2 days ago)
     - Content: API documentation and examples
     - Value: High - reference material
     - Suggestion: Promote to spec context/references/

   - File: context/scratch/transcripts/debug-session.txt (45 KB, modified yesterday)
     - Content: Debugging session output
     - Value: Low - temporary troubleshooting notes
     - Suggestion: Delete

   ### Recommendations
   1. [Specific promotion actions]
   2. [Any general observations about the spec work]
   ```

7. Ask the user if they want to:
   - Proceed with the suggested promotions
   - Keep everything as-is
   - Manually select which files to promote/delete
