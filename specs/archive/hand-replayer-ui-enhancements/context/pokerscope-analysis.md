# Pokerscope Visual Analysis

Reference: `context/Screenshot 2026-07-01 at 10.59.42 AM.png`

## Layout

- Table visualization occupies full content width (sidebar on left, table dominates the viewport)
- Action timeline sits directly below the table as a horizontal scrollable row
- Navigation controls (arrows) are below the timeline
- Utility buttons (Reveal, Analyse, Share, Notes) at bottom-right

## Table Rendering

| Element | Pokerscope | Current Lolfold |
|---------|------------|-----------------|
| Table shape | Thin white/gray ellipse **outline only** on black background | Filled dark green pill (`#0d1a0f`) with border |
| Background | Pure black | `#0a0a0a` (close, acceptable) |
| Felt | None — just the outline | Green fill + inner border |
| Center text | "2/5 NL" + "Total pot: $67" | Game info + "Total pot: $X" (similar) |

## Seat Badges

| Element | Pokerscope | Current Lolfold |
|---------|------------|-----------------|
| Shape | Large circle, **outline only** (thin gray/white stroke) | Small filled circle (`r=20`) |
| Size | ~2x larger than current | `SEAT_RADIUS = 20` |
| Content | Position code only inside circle | Position + stack inside circle |
| Stack display | Dollar amount **below** the circle | Inside circle (small text) |
| Player tag | Colored label below circle (e.g., "FISH" in cyan, "HERO" in green) | "HERO" badge below only for hero |
| Active indicator | Cyan/teal full ring glow around circle | Amber pulsing ring |
| Folded state | Not visible in screenshot | Dimmed outline |

## Cards

| Element | Pokerscope | Current Lolfold |
|---------|------------|-----------------|
| Face-down | Dark gray rounded rectangles beside seat | Small cards beside seat |
| Hero cards | Large, suit-colored (red hearts, blue diamonds), clearly readable | Smaller FaceUpCard components |
| Board cards | Gray placeholder rectangles in center when undealt | FaceUpCard in center |
| Card position | Flanking the seat on both sides | To the right of seat only |

## Dealer Button

- Separate circular "D" badge, gray background, positioned floating between seats
- Current Lolfold: No dealer button indicator

## Bets

| Element | Pokerscope | Current Lolfold |
|---------|------------|-----------------|
| Chip icon | Small red/pink horizontal bar | ChipStack component |
| Amount | Dollar text below the chip icon | Amount on/near chips |
| Position | Between seat and center (similar) | Between seat and center (similar) |

## Action Timeline

| Element | Pokerscope | Current Lolfold |
|---------|------------|-----------------|
| Layout | Horizontal scrollable row of colored pills | ActionTimeline component (vertical list?) |
| Action pills | Rounded rectangles with action text + amount | Unknown current rendering |
| Colors | Teal/blue for posts/calls/raises, red/coral for folds | N/A |
| Player label | Below the action pill in smaller text | N/A |
| Hidden actions | Grayed out "Hidden" pills with eye-slash icon | N/A |
| Scrolling | Horizontal overflow with hidden scrollbar | N/A |

## Color Palette

| Usage | Pokerscope Color | Current Lolfold |
|-------|-----------------|-----------------|
| Background | Pure black `#000` | `#0a0a0a` |
| Table outline | Light gray/white thin stroke | Dark green fill + gray border |
| Seat outlines | Light gray/white thin stroke | Filled navy/dark green |
| Active seat | Cyan/teal glow | Amber `#fbbf24` |
| Hero accent | Green (badge) | Emerald (badge + seat fill) |
| Player tags | Cyan/teal | N/A (no tags) |
| Action: fold | Red/coral | N/A |
| Action: other | Teal/blue-teal | N/A |
| Bet chips | Red/pink bar | ChipStack (colored) |
| Text primary | White | `#e5e7eb` |
| Text secondary | Light gray | `#9ca3af` |

## Key Design Principles Observed

1. **Minimal geometry** — outlines over fills, thin strokes, no simulated textures
2. **Information density via layout** — position inside circle, stack below, tag below that, cards beside
3. **Color used sparingly** — mostly monochrome with accent colors for active/hero/tags only
4. **Horizontal action timeline** — serves as both progress indicator and action log, scrollable
5. **Cards as first-class visual elements** — hero cards are large and prominently colored
