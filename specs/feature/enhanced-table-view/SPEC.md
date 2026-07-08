# Enhanced replayer poker table — full-width, larger, easier to see

## What this is about

This is about the **hand replayer's poker table** — the visual felt/table that
hands are replayed on. It is NOT a data grid, list, or spreadsheet. "Table"
here means the literal poker table graphic.

Component chain in `lolfold-frontend`:
`src/pages/HandDetailPage.tsx` → `src/components/replayer/HandReplayer.tsx`
→ `src/components/replayer/PokerTable.tsx` (the SVG felt).

## Problem

When replaying a hand, the poker table is rendered small — its width is capped
(`HandReplayer` uses `max-w-4xl`), so on larger screens there is wasted space
and the table / cards / player seats are harder to see than they need to be.

## Goal

Make the replayer poker table **larger and easier to see**, using the full
width of the screen. On desktop it should span the full available width
(within the app's normal page padding), which enlarges the whole table, seats,
cards, and chips proportionally.

## Reference

`screenshots/` contains a screenshot from the **public PokerScope website**
(pokerscope.app). It is an **external style reference** — an example of a
large, clear, full-width poker table layout to aim for. It is NOT a lolfold
screen and does NOT point at any lolfold component. Use it only for look-and-feel.

## Scope

- Frontend only (`lolfold-frontend`).
- The replayer table and its container: `HandReplayer.tsx` (width cap) and
  `PokerTable.tsx` (the SVG, already `w-full`).
- Presentation/layout only — no change to replay logic, hand data, or controls.

## Requirements

- The replayer poker table spans the full viewport width on desktop (within the
  app's normal page padding — not overflowing off-screen). In practice this
  means relaxing / removing the `max-w-4xl` cap on the replayer container.
- The table and everything on it (seats, hole cards, board, pot/chips) are
  visibly larger and easier to read than today, scaling up with the width.
- Remains responsive: still looks correct and usable on mobile (the app is
  mobile-first, Tailwind CSS v4). Full-width on desktop must not break small screens.
- Dark mode (the app default) still looks correct.
- Replay controls and behavior are unchanged.

## Acceptance criteria

- On desktop, the replayer poker table renders full-width and noticeably larger.
- The table remains correct and usable on a narrow (mobile) viewport.
- Dark mode renders correctly.
- Replay logic/controls unchanged (presentation-only change).
- `npm run build`, `npm run test:run`, and `npx tsc -b --noEmit` all pass.

## Notes for the implementer

- Start from `HandReplayer.tsx` (the `max-w-4xl` width cap is the main lever)
  and confirm `PokerTable.tsx`'s SVG scales with its container (`w-full`,
  `viewBox`-based, so it should).
- Prefer Tailwind utility changes over new CSS, matching the existing approach.
- The reference image is PokerScope's public site, for visual inspiration only —
  do not try to match it pixel-for-pixel or copy any of its non-table UI.
