# Worktree Layout Reference

Directory layout produced by `setup-worktree.sh`. Binding interlocks for `setup-worktree.sh`, `stage-context.sh`, and `persist-plan.sh`.

## Exact Path Contract

### Decomposed work (initiative/slice)
```
specs/feature/<initiative>/<slice>/
├── <slice>.spec.md
├── status.md
├── context/
├── plans/                        # TRACKED — plan copied here before cleanup
│   └── <repo-name>.plan.md
└── repo/                         # gitignored — ephemeral
    └── <repo-name>/              # git worktree on feat/<slice>
        ├── _working/<slice>/     # staged spec + live plan (lost on cleanup)
        └── src/
```

### Standalone specs (no initiative)
```
specs/feature/<key>/
├── <key>.spec.md
├── status.md
├── context/
├── plans/
│   └── <repo-name>.plan.md
└── repo/
    └── <repo-name>/
        ├── _working/<key>/
        └── src/
```

## Key Rules
- `repos/<repo-name>/` stays on the default branch — feature work NEVER lands there
- Feature work happens ONLY in spec worktrees (`specs/.../repo/<repo-name>/`)
- `_working/<key>/` is staged by `stage-context.sh` and lost on worktree cleanup
- `plans/<repo-name>.plan.md` is persisted by `persist-plan.sh` BEFORE worktree removal
- `repo/` directories are gitignored
- Branch name convention: `feat/<key>` (or the meta-branch if it matches `^(feat|fix|chore)/`)
