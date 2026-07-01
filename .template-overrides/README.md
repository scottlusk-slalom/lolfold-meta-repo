# .template-overrides/

Files placed here prevent `scripts/update-template.sh` from overwriting the
corresponding framework file during a template sync.

The path inside this directory must mirror the framework path exactly.

## Example

To protect `.claude/commands/scaffold-repo.md` from being overwritten:

```
.template-overrides/
└── .claude/
    └── commands/
        └── scaffold-repo.md   ← file content is ignored; presence alone skips the sync
```

## Rules

- Only framework paths (listed under `framework:` in `template-manifest.yaml`) can be overridden.
- Merge paths (`merge:`) and project paths (`project:`) are never overwritten regardless.
- This directory itself is listed under `project:` and is never touched by the sync.

## When to use

Use overrides when your derived repo has customized a framework file and you want
to keep those customizations across future template upgrades. You are responsible
for manually reviewing upstream changes to overridden files.
