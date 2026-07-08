# Enhanced table view — full-width, larger, easier to read

## Problem

The table view is currently constrained and small — hard to read at a glance.
It does not use the available horizontal space, leaving wasted margins and
cramped rows.

## Goal

Make the table larger and easier to see. It should span the **full width of
the screen** and present its rows/columns with more breathing room so the data
is easy to scan.

## Reference

See `screenshots/` for an example of the target look and feel.

<!-- Screenshots to be added by the human before kickoff:
     screenshots/current.png  — the table as it looks today
     screenshots/target.png   — the desired full-width, larger layout
-->

## Scope

- Frontend only (`lolfold-frontend`).
- The table view component and its container/layout.

## Requirements

- The table occupies the full width of the viewport (edge-to-edge within the
  app's normal page padding — not overflowing off-screen).
- Rows and text are larger / more legible than today (increased row height,
  font size, and/or spacing — match the reference screenshot).
- Remains responsive: still usable on mobile (the app is mobile-first,
  Tailwind CSS v4). Full-width on desktop must not break the small-screen layout.
- Dark mode (the app default) still looks correct.
- No change to the table's data or behavior — this is layout/presentation only.

## Acceptance criteria

- The table view renders full-width on desktop, matching the reference.
- Rows/text are visibly larger and easier to read than the current view.
- The layout is still usable and not broken on a narrow (mobile) viewport.
- Existing tests pass; build and type-check are clean.
- A test (or updated test) covers the new layout where practical.

## Notes for the implementer

- Confirm which component renders the table (search `src/components/` and
  `src/pages/`) before changing layout.
- Prefer Tailwind utility changes over new CSS where possible, to match the
  existing styling approach.
