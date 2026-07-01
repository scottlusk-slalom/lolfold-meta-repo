# Specs Directory

Specs are organized by type, with each containing a functional spec, technical plan, and curated context.

## Directory Structure

| Directory | Content |
|-----------|---------|
| `feature/` | New functionality or capabilities |
| `bug/` | Bug fixes or defect resolution |
| `chore/` | Infrastructure, tooling, maintenance |
| `design/` | Design exploration or prototyping |
| `planning/` | Phase decomposition and slice maps |
| `archive/` | Completed specs (moved here by `/finalize-spec`) |

## Nesting Standard

Two-level nesting is supported:

- **Decomposed work**: `specs/<type>/<initiative>/<slice>/`
- **Standalone**: `specs/<type>/<id>/`

## Worktree Convention

Repositories are cloned to `specs/<type>/<id>/repo/<repo-name>/` on branch `feat/<id>`.

## Workflow

See `META-REPO-GUIDE.md` for the full spec workflow.
