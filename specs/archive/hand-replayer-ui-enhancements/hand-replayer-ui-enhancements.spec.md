---
type: feature
status: archived
priority: medium
created: 2026-07-01
updated: 2026-07-01
archived_date: 2026-07-01
tags: ["ui", "replayer", "frontend"]
related: []
---

# Hand Replayer UI Enhancements Specification

## Problem Statement

The hand replayer table visualization is too small. The current `HandDetailPage` layout places the replayer and hand details side-by-side on desktop (`lg:grid-cols-2`), giving the table SVG only ~50% of viewport width. The table's 520:380 aspect ratio means it needs horizontal space to render readable player positions, stacks, cards, and bet amounts.

Additionally, the replayer has no visual fidelity to Pokerscope (the reference poker hand replayer). The current implementation uses a generic dark UI with minimal styling — no distinct felt texture, basic seat badges showing only position codes, and no polish matching the reference.

## Objectives

1. Make the table replayer large enough to be comfortably readable without zooming
2. Restructure the hand detail page layout so the table takes priority (top, full width) and hand details are below
3. Bring the replayer visual styling closer to Pokerscope's reference UI

## Success Criteria

### Layout
- [ ] Table replayer renders at full content width on all breakpoints
- [ ] Hand details (players table, actions, confidence) appear below the replayer
- [ ] No horizontal scrolling introduced at any viewport size
- [ ] Mobile experience is not degraded (was already stacked)

### Visual Fidelity — Table
- [ ] Table rendered as thin ellipse **outline only** (no filled green felt)
- [ ] Background remains near-black
- [ ] Seat badges are large outlined circles (~2x current radius), position text centered inside
- [ ] Stack amount displayed below the seat circle (not inside)
- [ ] Player tags/labels (e.g., "HERO", player name) displayed below stack amount
- [ ] Active seat indicator is cyan/teal ring glow (replacing amber pulse)
- [ ] Dealer button rendered as separate "D" badge floating between seats

### Visual Fidelity — Cards
- [ ] Face-down cards rendered as dark gray rounded rectangles flanking the seat
- [ ] Hero cards are large, suit-colored (red for hearts/diamonds, blue/black for spades/clubs)
- [ ] Board card placeholders shown as gray rectangles when street not yet dealt

### Visual Fidelity — Bets & Pot
- [ ] Bet indicator uses small colored bar/chip icon with dollar amount text
- [ ] Center pot display: stakes info (e.g., "2/5 NL") + "Total pot: $X"

### Visual Fidelity — Action Timeline
- [ ] Horizontal scrollable row of colored action pills (already exists, may need color tweaks)
- [ ] Teal/blue-teal for posts/calls/raises, red/coral for folds (adjust from current emerald/rose/violet)
- [ ] Player position label in bold before action text (already implemented)

### Functionality
- [ ] All replayer controls remain functional (forward/back, street jump, progress bar)
- [ ] Active player animation works at new size
- [ ] Hero cards and board cards render correctly at larger scale
- [ ] Chip stacks and bet amounts remain readable and properly positioned

## Scope

### In Scope

- `HandDetailPage.tsx` layout restructure (grid change)
- `PokerTable.tsx` SVG scaling and styling overhaul
- `HandReplayer.tsx` container sizing
- Replayer visual styling (felt, seats, cards, badges)
- `ReplayerControls.tsx` if sizing adjustments needed

### Out of Scope

- New replayer features (autoplay, keyboard navigation, sound)
- Backend changes
- Hand parsing changes
- Mobile-specific gesture controls
- Other pages (hand list, player profile, search)

## Benefits

1. **Readability** — Players can see table state at a glance without squinting or zooming
2. **Usability** — Stacked layout gives both the table and hand details adequate space instead of cramming both into one row
3. **Polish** — Closer Pokerscope fidelity makes the app feel like a purpose-built poker tool rather than a generic data viewer

## Dependencies

- ~~Reference screenshot from Pokerscope~~ — Provided: `context/Screenshot 2026-07-01 at 10.59.42 AM.png`
- Visual analysis: `context/pokerscope-analysis.md`

## Assumptions

- The SVG-based rendering approach is retained (not switching to canvas or WebGL)
- The existing `useReplayerState` hook and data model are sufficient — this is a presentation-layer change
- No new data fields are needed from the API
