---
title: Hand replayer display fixes — seats, folded cards, dealer button, card layout
type: bug
status: specified
quality_gate: standard
created: 2026-07-10
repos:
  - lolfold-frontend
---

# Hand replayer display fixes

Four display bugs in the hand replayer's poker table. All are in
`lolfold-frontend`, component `src/components/replayer/PokerTable.tsx`
(the SVG felt), rendered via `HandDetailPage.tsx → HandReplayer.tsx`.

This is presentation-only — no change to replay logic, parsing, or data.

## Reference

`screenshots/` contains a screenshot from the public PokerScope website
(pokerscope.app). It is an **external style reference** for how a clear poker
table looks — NOT a lolfold screen and NOT a pointer to a component. Use it
only for look-and-feel.

## Bugs to fix

### 1. Always show the whole table of players

Every player seat must remain visible for the **entire hand** — no player
should disappear from the table at any point (including after they fold, are
all-in, or are otherwise out of the action). A folded player's seat stays on
the table (it may be visually de-emphasized), but the seat/position/name must
not be removed.

### 2. A player's cards disappear when they fold

When a player folds, their cards should be **removed** from the table at that
point in the replay. The seat stays (per #1), but the cards go. This applies to
both the hero's face-up cards and other players' face-down cards.

(Current behavior in `PokerTable.tsx`: folded players are rendered as a dimmed
seat with no cards — but issue #1 indicates whole players/seats are vanishing.
Fix so the seat always persists and only the CARDS are removed on fold.)

### 3. Always show the dealer button, in the correct location

The dealer (button) marker must **always** be shown on the table, positioned at
the correct player's seat (the button/dealer position for the hand).

Current behavior: the dealer seat is found via
`step.players.findIndex(p => /^(BU|BTN|D|Dealer|Button)$/i.test(p.position))`.
When no player's `position` matches that exact pattern, `findIndex` returns
`-1` and the button is not drawn — so it is not "always" shown. Make button
placement robust to the position labels the parser actually produces (e.g. also
handle lowercase, "btn"/"button"/"dealer"/"D"/"BU", or derive the button seat
from the hand data if the position label is absent). The button must render on
every hand at the dealer's seat.

### 4. A player's two cards should be next to each other

A player's two cards must be drawn **adjacent to each other** (side by side) on
one side of that player's seat — NOT split with one card on each side of the
seat icon.

Current behavior: both hero and non-hero cards flank the seat (one at
`seat.x - radius - offset`, the other at `seat.x + radius + offset`), placing
them on opposite sides. Change so both cards sit together as a pair.

## Acceptance criteria

- Every player seat stays visible for the whole hand; no player vanishes.
- A player's cards are removed when they fold (seat remains).
- The dealer button renders on every hand, at the correct seat, regardless of
  how the player's position is labeled.
- Each player's two cards render adjacent (side by side), not on opposite sides
  of the seat.
- Works on desktop and mobile (mobile-first, Tailwind v4); dark mode correct.
- Replay logic/controls unchanged.
- `npm run build`, `npm run test:run`, and `npx tsc -b --noEmit` all pass.
- Add/adjust tests where practical (e.g. dealer-button placement for varied
  position labels; folded player retains seat but loses cards).

## Notes for the implementer

- All four fixes are in `src/components/replayer/PokerTable.tsx`. Read
  `useReplayerState.ts` to understand the `step.players[]` shape (`position`,
  `folded`, `isHero`, `stack`, `currentBet`) and how the dealer/button could be
  derived if the position label is missing.
- Verify against a few real hands in the replayer, including one where a player
  folds and one where the button position label is non-standard.
- The PokerScope screenshot is inspiration for the target look only — do not
  copy its non-table UI or try to match pixel-for-pixel.
