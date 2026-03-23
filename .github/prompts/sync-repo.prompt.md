---
description: Clone or update a repository in a spec's repo/ directory
name: sync-repo
argument-hint: repo-url, branch
agent: agent
---

Clone or update a repository in a spec's repo/ directory.

## Instructions

1. Determine the current spec directory:
   - Check if the current working directory is within a spec directory
   - If not, ask the user which spec to work with (use /list-specs to show options)

2. Check known repositories configuration:
   - Read project/project-repositories.yaml for known repositories
   - If the user mentions a known repository by name, use its configuration
   - Show available known repositories if the user asks or needs guidance

3. Ask the user for repository information:
   - Repository URL (git clone URL) - use config from project-repositories.yaml if available
   - Optional: specific branch or tag to check out (default from config if available)
   - Optional: custom directory name (defaults to repo name or typical clone location from config)

4. Check if the repository already exists in the spec's `repo/` directory:
   - If it exists: Run `git pull` to update it
   - If it doesn't exist: Run `git clone` to clone it

5. Handle errors gracefully:
   - If clone fails (invalid URL, auth required), explain the error
   - If pull fails (uncommitted changes, conflicts), provide guidance

6. **Create a feature branch** in the cloned repository:
   - Determine the current meta-repo branch name (run `git branch --show-current` in the meta-repo root)
   - Create and check out a matching branch in the cloned repo (e.g., if meta-repo is on `feature/42-add-auth`, create the same branch in the cloned repo)
   - If the user specifies a different branch name, use that instead
   - If the repo was updated (pull, not clone), ask the user if they want to create/switch to a feature branch

7. After successful sync:
   - Show the repository location and the active branch
   - Reference the repository's context files from project/project-repositories.yaml configuration
   - If the repo has an AGENTS.md file (check config for location), mention it and suggest reading it
   - If the repo has additional context files listed in config, mention those too

8. Remind the user that:
   - The `repo/` directory is gitignored in the meta-repo
   - Changes to cloned repos should be committed in those repos, not the meta-repo
   - Always work on a feature branch in cloned repos — never commit directly to the default branch
   - Use `context/scratch/` for notes about work done across repos

Example:
```
✓ Cloned my-org/my-project to specs/feature/123-add-auth/repo/my-project
  Branch: feature/123-add-auth (created from main)
  Configuration: Using settings from project-repositories.yaml

  Found AI context files:
  - AGENTS.md (root) - Primary repository guidance
  - CLAUDE.md (root) - Additional context
  - repo/my-project/README.md - Toolkit-specific guidance

  Remember: This repo/ directory is gitignored. Commit changes within
  the cloned repo, and use context/scratch/ for cross-repo notes.
  Always work on a feature branch — never commit directly to the default branch.
```
