# Generate Spec

Generate a specification, implementation plan, context scratch directory, and status tracker for a unit of work.

## Lifecycle Stage

`generate-spec` transitions status to **specified**.

## Instructions

### Phase 1: Gather Context

1. Read `org/` directory for organizational standards and patterns
2. Read `project/` and `architecture/` for project-level context
3. Check `specs/` for related or overlapping specs
4. Review `project/project-repositories.yaml` for known repositories

### Phase 2: Analyze

1. Ask the user for:
   - **What** they want to build/fix/change (the requirement)
   - **Spec type**: feature, bug, chore, design, or planning
   - **Spec name**: descriptive kebab-case name
   - **Optional ID**: ticket/issue ID
   - **Target repository(ies)**: which repos are affected

2. Analyze the target codebase(s):
   - Clone or reference repos as needed
   - Understand current state relevant to the requirement
   - Identify integration points and dependencies

3. Ask any outstanding clarifying questions before proceeding to planning

### Phase 3: Plan & Generate

1. Create the spec directory structure:
   ```
   specs/{type}/{id}-{name}/
   ├── {id}-{name}.spec.md      # Functional spec (WHAT/WHY)
   ├── {id}-{name}.plan.md      # Technical plan (HOW)
   ├── status.md                # Lifecycle status tracker
   ├── context/                 # Curated context for this spec
   │   └── scratch/             # Volatile working memory
   └── repo/                    # Cloned repositories (gitignored)
   ```

2. Generate the spec using `docs/templates/specname.spec.md`:
   - Fill problem statement, objectives, success criteria
   - Define explicit scope boundaries
   - Identify dependencies and assumptions

3. Generate the plan using `docs/templates/specname.plan.md`:
   - Break work into RED/GREEN/Refactor-compatible tasks
   - Each success criterion should map to a test
   - Identify affected systems and testing strategy

4. Create `status.md`:
   ```markdown
   ---
   lifecycle: specified
   created: {today}
   updated: {today}
   approval_gate: pending
   ---
   # Status: {spec-name}
   
   ## Lifecycle
   - [x] Specified (generate-spec)
   - [ ] Planned (approve-spec)
   - [ ] Executed (execute-spec)
   - [ ] Submitted (PR created)
   - [ ] Archived (archive-spec)
   
   ## Approval Gate
   Status: **pending**
   Approver: —
   Date: —
   Notes: —
   ```

5. Populate `context/scratch/` with analysis findings:
   - Codebase analysis notes
   - Relevant patterns discovered
   - Questions resolved during generation

### Phase 4: Confirm

1. Present the generated spec and plan to the user for review
2. Highlight any assumptions or areas needing clarification
3. Remind user to run `approve-spec` when ready to proceed to execution

## Agent References

- Uses: `agents/spec-writer.md` for spec generation
- Uses: `agents/context-curator.md` for context gathering
