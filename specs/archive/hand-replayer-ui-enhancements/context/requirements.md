# Requirements — hand-replayer-ui-enhancements

## REQ-1: Increase replayer table size

The hand replayer table visualization must occupy the full available width of the content area. The current 50% width constraint (from `lg:grid-cols-2` layout) must be removed so the SVG table renders at a size where player positions, stacks, cards, and bets are comfortably readable without zooming.

## REQ-2: Layout restructure — table above, hand details below

On the hand detail page, the table replayer must be positioned above the structured hand view (players table, street-by-street actions, confidence indicators). This stacked layout applies at all breakpoints. The hand details section becomes a scrollable area below the replayer.

## REQ-3: Visual fidelity to Pokerscope

Reference: `context/Screenshot 2026-07-01 at 10.59.42 AM.png`
Analysis: `context/pokerscope-analysis.md`

The replayer UI must match Pokerscope's minimal geometric style:

### Table
- Thin ellipse **outline only** on black background (no filled green felt, no inner border)
- White/light-gray stroke, no fill

### Seats
- Large outlined circles (increase `SEAT_RADIUS` from 20 to ~35-40)
- Position text centered inside circle (no stack inside)
- Stack as dollar amount **below** the circle
- Player name/tag below the stack
- Active player: cyan/teal ring glow (replace amber `#fbbf24` with `~#06b6d4`)
- Seat circles are outline only (no fill), except hero which may have subtle accent

### Dealer Button
- Separate circular "D" badge, gray fill, floats between the dealer seat and center

### Cards
- Face-down: dark gray rounded rectangles flanking the seat (both sides)
- Hero cards: large, suit-colored values (red hearts, blue diamonds, etc.)
- Board placeholders: gray rounded rectangles in center row

### Bets
- Small colored bar/chip icon with dollar amount as text below
- Replace current `ChipStack` SVG component with simpler bar + text

### Action Timeline Colors
- Adjust palette: teal/blue-teal for posts/calls/raises, red/coral for folds
- Current emerald/violet scheme shifts to match Pokerscope's teal-dominant palette

## REQ-5: Seat ordering must be clockwise

Players must be arranged clockwise around the table (matching real poker table action direction). The current implementation lays seats counter-clockwise, causing the active player highlight to appear to move "backwards" around the table as actions progress.

## REQ-4: Replayer remains functional at new size

All existing replayer functionality must continue to work at the larger size:
- Street jump buttons
- Forward/back navigation
- Progress bar
- Active player indicator
- Hero badge and hole card display
- Board card rendering
- Chip stack / bet displays
