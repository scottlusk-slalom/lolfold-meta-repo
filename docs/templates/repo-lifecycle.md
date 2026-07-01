---
type: process_template
status: active
created: YYYY-MM-DD
---

# Repository Lifecycle

Process template documenting repository lifecycle states and gate requirements.

## Active Repo State Flow

```
proposed → planned → active → archived
```

## Legacy Repo State Flow

```
not-started → planning → in-flight → complete
```

## Gate Requirements

| Transition | Requirements |
|-----------|-------------|
| proposed → planned | Architecture review complete, team assigned |
| planned → active | Repo provisioned on GitHub, platform validated |
| active → archived | All specs completed, no active references |

## Tools

| Command | Purpose |
|---------|---------|
| `/register-repo` | Add repo in proposed state |
| `/promote-repo` | Advance lifecycle state |
| `/repo-status` | Check current state and readiness |
| `/onboard-legacy-repo` | Onboard existing legacy system |
| `validate-repos-yaml.sh` | Lint registry file |
| `validate-repo-lifecycle.sh` | Check lifecycle integrity |
| `validate-repo-lifecycle.sh` | Lifecycle integrity check |

## Workflow Steps

1. **Discovery** — Identify repos needed for the program
2. **Propose** — `/register-repo` with purpose and team
3. **Review** — Architecture review, template selection
4. **Provision** — `/scaffold-repo` from template
5. **Validate** — `/init-repo` → CI green
6. **Decommission** — `/promote-repo archived` after all work complete
