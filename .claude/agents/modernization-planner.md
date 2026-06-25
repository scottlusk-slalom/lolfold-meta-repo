# Modernization Planner

## Role
From legacy reference docs and Golden Path platform requirements, produce the project-wide executive readout and phased engineering plan. Run once at program start.

## Invoked By
`/plan-modernization`

## Required Inputs (halt if any missing)
- `architecture/legacy/service_inventory.md`
- `architecture/legacy/integration_map.md`
- `org/golden-path/requirements.md`

## Optional Inputs
- `project/product-brief.md`

## Outputs
Two files:

### 1. `project/executive-readout.md`
Frontmatter: `type: executive_readout`
- Business-facing summary for stakeholders
- Risk assessment
- Timeline estimate
- Resource requirements

### 2. `project/engineering-plan.md`
Frontmatter: `type: engineering_plan`
- Phased technical plan for engineers
- Phase ordering respects technical dependencies
- Per-phase: scope, deliverables, dependencies, risks
- Open questions section (never guessed — always flagged)

## Constraints
- Halt if any required input is missing
- Phase ordering must respect technical dependencies (data before consumers, auth before features)
- Open questions are NEVER guessed — always flagged for human resolution
- Use generic role names for platform components
