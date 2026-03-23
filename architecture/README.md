# Architecture Context

This directory contains architecture documentation following C4 Model conventions. Architecture context describes the systems being built and their interactions.

## C4 Model Overview

The C4 Model provides four levels of abstraction:

1. **System Context** - The big picture: the system and its external actors (users, external systems)
2. **Container** - Major applications, services, data stores, and their responsibilities
3. **Component** - Key components within containers and their interactions
4. **Code** - (Optional) Source code structure or important classes

## File Naming Convention

Files use a hierarchical numbering scheme:

```
architecture/
├── README.md                                    # This file
├── 00-[system-name].md                          # System context level
├── 00-01-[container-name].md                    # Container level
├── 00-01-01-[component-name].md                 # Component level
└── ...
```

**Examples:**
- `00-my-platform.md` - System context for the platform
- `00-01-api-service.md` - Container: the API service
- `00-01-01-auth-module.md` - Component: authentication module

## File Template

Each architecture file should include:

```markdown
# [Element Name]

## Purpose
[Technical description of what this element does]

## Diagram
[Mermaid diagram showing relationships]

## Dependencies
- [List of dependencies on other elements]

## Interfaces
- [APIs, contracts, or integration points]

## Related Documentation
- [Links to requirements, plans, decisions]
```

## Scope

This architecture context is **project-level** in the three-tier memory system:
- **Org level**: Enterprise patterns, standards (cached from external sources)
- **Project level**: This directory - systems and architecture for this project
- **Repo level**: Architecture docs within individual cloned repositories

## See Also

- `../project/` - Project context (briefs, charters)
- `../requirements/` - Functional requirements (PRDs)
- `../docs/THREE_TIER_MEMORY.md` - Memory system documentation
