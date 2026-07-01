---
status: approved
created: 2026-07-01
updated: 2026-07-01
---

# Hand Replayer UI Enhancements - Technical Implementation Plan

## Approach

Two-phase approach, both now unblocked:

**Phase 1 — Layout restructure.** Change `HandDetailPage` grid from `lg:grid-cols-2` to single-column stacked layout. Replayer full-width on top, hand details below.

**Phase 2 — Visual overhaul.** Rewrite `PokerTable.tsx` to match Pokerscope's minimal geometric style: outline-only ellipse table, larger outlined seat circles, stacks/names below seats, cyan/teal active indicator, dealer button badge, simplified bet display. Adjust `ActionTimeline.tsx` color palette. Reference: `context/pokerscope-analysis.md`.

## Implementation Tasks

### 1. Layout Restructure (can start now)

- [ ] Change `HandDetailPage.tsx` grid from `grid-cols-1 lg:grid-cols-2` to single-column stacked layout
- [ ] Move replayer to top, hand details below
- [ ] Add optional max-width constraint on replayer so it doesn't become absurdly wide on ultrawide monitors (e.g., `max-w-4xl mx-auto`)
- [ ] Verify mobile layout is unchanged (already single-column)
- [ ] Test that replayer controls don't break at wider sizes

### 2. Visual Overhaul — Table (`PokerTable.tsx`)

- [ ] Replace filled green pill with thin ellipse outline (no fill, light gray stroke)
- [ ] Increase `SEAT_RADIUS` from 20 to ~35-40
- [ ] Change seats to outline-only circles (no fill except subtle hero accent)
- [ ] Move stack display below circle, remove from inside
- [ ] Add player name/tag label below stack
- [ ] Change active indicator color from amber `#fbbf24` to cyan/teal `#06b6d4`
- [ ] Add dealer button "D" badge element
- [ ] Simplify bet display: replace `ChipStack` with small bar icon + dollar text
- [ ] Adjust face-down card rendering: dark gray rectangles, flanking both sides of seat
- [ ] Make hero cards larger with suit-colored values
- [ ] Add board card placeholders (gray rectangles) when street not dealt
- [ ] Adjust SVG viewBox if needed for larger seats (may need wider/taller)

### 3. Visual Overhaul — Action Timeline (`ActionTimeline.tsx`)

- [ ] Shift color palette: teal/blue-teal for posts/calls/raises, red/coral for folds
- [ ] Consider adding "Hidden" pill style for future actions (stretch)

### 4. Testing & Polish

- [ ] Visual regression check at common breakpoints (375px, 768px, 1024px, 1440px)
- [ ] Verify all replayer interactions work (step through, street jump, etc.)
- [ ] Check performance — larger SVG shouldn't cause jank
- [ ] Confirm no regressions in mobile touch interactions

## Affected Systems

- **lolfold-frontend** — `src/pages/HandDetailPage.tsx` (layout), `src/components/replayer/PokerTable.tsx` (styling), `src/components/replayer/HandReplayer.tsx` (container)

## Testing Strategy

### Test Scenarios
1. Navigate to a hand detail page — replayer should be full-width at top, details below
2. Step through a multi-street hand — all controls work at new size
3. View on mobile (375px) — layout stacks correctly, no horizontal scroll
4. View on desktop (1440px) — table is large and readable, max-width prevents stretching to absurd sizes

### Validation Steps
- [ ] Dev server visual check at each breakpoint
- [ ] Existing component tests still pass (if any)
- [ ] No Tailwind purge issues with new classes

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Large SVG causes scroll/overflow issues | Medium | Low | Test at breakpoints, add `overflow-hidden` if needed |
| Pokerscope fidelity is too complex to replicate in SVG | Medium | Medium | Define "good enough" threshold; can iterate |
| Layout change breaks other elements on HandDetailPage (similar hands, annotations) | Low | Low | These are below both sections and just flow naturally |

## Notes

Both phases are unblocked. Phase 1 is a quick layout change; Phase 2 is the bulk of the work (PokerTable rewrite). Can be done as a single PR since it's all frontend presentation-layer in one component tree.
