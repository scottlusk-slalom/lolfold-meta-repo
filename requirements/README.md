# Requirements Context

This directory contains PRDs, test strategy, and other functional scope documentation that serves as the source of truth for product/project functionality.

## Contents

- **PRDs (Product Requirements Documents)** - Detailed functional requirements with embedded test plans
- **Test Strategy** - Overall testing approach and standards
- **User Stories** - (Optional) User-centric requirement formats
- **Acceptance Criteria** - (Optional) Testable success conditions

## Directory Structure

```
requirements/
├── README.md                    # This file
├── test-strategy.md             # Overall test strategy document
├── prd-[feature-name].md        # PRD with embedded test plan
└── ...
```

## PRD Structure

Each PRD is a self-contained document for a large feature, including its test plan:

```markdown
# [Feature Name] PRD

## Overview
## Requirements
## Acceptance Criteria
## Test Plan           <-- Embedded in the PRD
## Dependencies
```

**Template**: `../docs/templates/prd-feature-name.md`

## Purpose

Requirements context is the **functional source of truth** for what the product/project should do. This is distinct from:

- **Architecture** - How systems are structured (technical)
- **Project** - Why we're doing this (business context)
- **Specs** - Individual work items to implement requirements

## Relationship to Specs

Requirements define *what* should be built. Specs (`../specs/`) define *how* individual pieces get implemented:

```
requirements/prd-feature-name.md
    └── informs → specs/feature/01-something/01-something.spec.md
                  specs/feature/02-another/02-another.spec.md
```

## See Also

- `../docs/THREE_TIER_MEMORY.md` - Memory system documentation
- `../project/` - Project briefs and charters
- `../specs/` - Implementation specs and plans
