# Create New Spec

Create a new spec directory with the proper structure and templates.

## Instructions

Ask the user for the following information:
1. **Spec type**: feature, bug, chore, design, or planning
2. **Spec name**: A descriptive kebab-case name (e.g., "user-authentication")
3. **Optional ID**: A ticket/issue ID if this maps to a tracking system (e.g., "123" or "PROJ-456")

Then:

1. Create the spec directory structure:
   - If ID is provided: `specs/{type}/{id}-{name}/`
   - If no ID: `specs/{type}/{name}/`
   - Create subdirectories: `context/scratch/` and `repo/`

2. Copy and customize the templates:
   - Copy `docs/templates/specname.spec.md` to the spec directory
   - Copy `docs/templates/specname.plan.md` to the spec directory
   - Rename both files to match the spec name
   - Update the YAML front matter with:
     - Current date for `created` and `updated` fields
     - Appropriate `type` value
     - Status: `draft` for spec, `not_started` for plan

4. Confirm the spec has been created and provide the path to the user.

5. Ask if the user wants to:
   - Start working on the spec immediately
   - Clone any repositories into the `repo/` directory (suggest checking project/project-repositories.yaml for known repositories)
   - Copy any context from project-level directories
