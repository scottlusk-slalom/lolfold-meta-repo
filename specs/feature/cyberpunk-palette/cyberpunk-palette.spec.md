---
title: 80s Cyberpunk Color Palette Redesign
type: feature
status: planned
quality_gate: standard
repos:
  - lolfold-frontend
priority: medium
created: 2026-07-15
updated: 2026-07-15
tags: ["ui", "frontend", "theming", "colors"]
related: []
---

# 80s Cyberpunk Color Palette Redesign

## Problem Statement

The lolfold web app currently uses a conventional, muted dark theme — neutral
gray surfaces (`--color-gray-*`) with standard Tailwind accent colors
(emerald/red/amber). It is functional but visually generic and forgettable.

We want a distinctive, high-energy visual identity: an **80s cyberpunk / synthwave**
aesthetic — deep near-black backgrounds with a subtle purple/blue cast, and vivid
neon accents (magenta/pink, cyan, electric purple, with hot-yellow highlights).
Think Blade Runner signage, Miami-at-night neon, retro-futurism.

This is a **pure theming change**. It re-skins the existing color system; it does
NOT change layout, components, copy, or behavior.

## Scope

The frontend centralizes its entire color system in a single Tailwind v4 `@theme`
block at **`lolfold-frontend/src/index.css`** (lines 3–56). All color tokens are CSS
custom properties consumed via Tailwind utility classes throughout the component
tree. Re-theming is therefore primarily a matter of redefining those token values —
no per-component color edits should be needed for the base palette.

Token groups to restyle (all in `src/index.css` `@theme`):

- **Gray scale** (`--color-gray-950` … `--color-gray-100`) — the surface/neutral
  ramp. Shift from neutral gray toward deep desaturated indigo/violet-black so
  backgrounds read as "night city," while preserving the light→dark ordering and
  roughly the same relative luminance steps (so existing contrast relationships
  hold).
- **Semantic surfaces** (`--color-bg-page`, `--color-bg-sidebar`, `--color-bg-surface`,
  `--color-bg-muted`) — currently neutral oklch. Re-tint to the cyberpunk dark base.
- **Core accents** (`--color-emerald-*`, `--color-red-*`, `--color-amber-*`) —
  remap to neon: cyan/teal-neon in place of emerald, hot magenta/red-pink in place
  of red, electric yellow in place of amber.
- **Poker action colors** (`--color-action-*`) — restyle to the neon family while
  KEEPING each action visually DISTINCT from the others (bet vs raise vs call/check
  vs fold vs win must remain easily told apart — this is functional, not decorative).
- **Card suit colors** (`--color-suit-club/diamond/heart/spade`) — restyle to fit
  the theme while keeping the four suits mutually distinguishable.
- **Profit/loss** (`--color-positive`, `--color-negative`) — neon green-cyan for
  positive, neon pink/red for negative; must stay intuitively "good vs bad."

Out of scope: `--sidebar-width*` (not colors), fonts, layout, component structure,
copy, and any API/backend work.

## Objectives

1. Replace the palette in `src/index.css` `@theme` with a cohesive 80s cyberpunk
   scheme: deep purple-black surfaces + neon magenta/cyan/purple/yellow accents.
2. Keep the change centralized in the theme tokens; avoid scattering hardcoded
   colors into components. If any component currently hardcodes a color (bypassing
   the tokens) and it clashes with the new theme, fix it to consume a token.
3. Preserve all semantic meaning: action colors stay mutually distinct; suits stay
   distinct; positive/negative stay intuitive; the light→dark neutral ramp keeps
   its ordering.
4. Maintain readable contrast for text and interactive elements against the new
   dark surfaces (target WCAG AA for body text where practical).

## Success Criteria

### Visual
- [ ] App backgrounds render as deep cyberpunk dark (purple/blue-black), not neutral gray.
- [ ] Primary accents read as neon (magenta/pink, cyan, electric purple, hot yellow).
- [ ] Poker action badges (bet/raise/call/check/fold/win) remain visually distinct from one another.
- [ ] Card suits (club/diamond/heart/spade) remain visually distinct from one another.
- [ ] Positive vs negative profit values remain intuitively distinguishable.

### Technical
- [ ] All palette changes live in `src/index.css` `@theme` (plus any necessary fixes to components that hardcoded colors).
- [ ] No layout, component-structure, copy, or behavioral changes.
- [ ] `npm run build` succeeds; typecheck passes; existing tests pass (no color-value assertions should break; if any test asserts a specific hex, update it to match the new token intentionally).
- [ ] No new hardcoded hex colors introduced in components where a theme token exists.

## Notes for Implementation

- Tailwind v4: tokens are defined as `--color-*` under `@theme` and surfaced as
  utility classes (e.g. `bg-gray-900`, `text-emerald-400`). Redefining the token
  value re-skins every usage automatically — prefer this over touching components.
- Suggested direction (implementer may refine): surfaces around `#0a0a12`–`#1a0f2e`
  (indigo/violet-black); neon magenta `#ff2d95`/`#ff6ac1`, neon cyan `#05d9e8`/`#54e6ef`,
  electric purple `#b026ff`/`#c77dff`, hot yellow `#f9f871`. These are a starting
  point, not a mandate — aim for a cohesive, high-contrast synthwave look.
- This is a visual change: verify by building and viewing the app, not just tests.
