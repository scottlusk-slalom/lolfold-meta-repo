---
title: 80s Cyberpunk Color Palette Redesign — Execution Plan
spec: cyberpunk-palette
type: feature
quality_gate: standard
status: approved
repos:
  - lolfold-frontend
created: 2026-07-15
---

# Execution Plan — cyberpunk-palette

## Scope

Single-repo, pure-theming change. Re-skin the Tailwind v4 `@theme` token block in
`lolfold-frontend/src/index.css` to an 80s cyberpunk/synthwave palette. No layout,
component-structure, copy, or behavioral changes.

## Repo Sequence

Only one repo is in scope, so sequencing is trivial — no cross-repo dependencies.

| Order | Repo | Depends on | Quality gate | Dispatch status |
|-------|------|-----------|--------------|-----------------|
| 1 | `lolfold-frontend` | — | standard | pending |

## Per-Repo Work (delegated to `/multi-repo-loop`)

The `lolfold-frontend` sub-agent runs `/multi-repo-loop cyberpunk-palette --repos lolfold-frontend --gates standard`
whole. That loop owns planning, TDD execution, adversarial review, and PR submission.
Expected work per the spec:

- Redefine color tokens in `src/index.css` `@theme` (gray ramp, semantic surfaces,
  core accents, poker action colors, card suit colors, profit/loss).
- Preserve semantic distinctness: action colors, card suits, positive/negative.
- Maintain WCAG AA body-text contrast against new dark surfaces where practical.
- Fix any component that hardcodes a clashing color to consume a token instead.
- `npm run build` + `npx tsc -b --noEmit` + `npm run test:run` must pass.

## Quality Gate (standard)

- `spec:review` — skip
- `spec:planning` — PAUSE (this gate)
- `spec:pr-review` — PAUSE (per companion PR)
- `spec:complete` — skip
- loop `--gates standard`

## Verification

Visual change — the sub-agent verifies by building and viewing the app, not tests
alone. Success criteria enumerated in `cyberpunk-palette.spec.md`.
