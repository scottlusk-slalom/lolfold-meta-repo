# Decisions — hand-replayer-ui-enhancements

## DEC-001: Layout change — table above, hand view below

**Decision:** Change `HandDetailPage` from a side-by-side (`lg:grid-cols-2`) layout to a stacked layout with the table replayer on top (full width) and hand details below.

**Rationale:** The table SVG is wide (520:380 aspect ratio) and benefits from horizontal space. The current 50/50 split constrains it to ~50% viewport width on desktop, making it too small to read comfortably.

**Status:** Proposed

## DEC-002: Minimal geometric style (outline-only table, no felt simulation)

**Decision:** Adopt Pokerscope's minimal geometric approach — thin ellipse outline on black, outlined seat circles, no filled felt texture.

**Rationale:** Pokerscope reference uses outlines over fills, thin strokes, no simulated textures. This is cleaner and more readable than the current green-felt approach.

**Reference:** `context/pokerscope-analysis.md`

**Status:** Decided

## DEC-003: Seat size increase (~2x)

**Decision:** Increase `SEAT_RADIUS` from 20 to ~35-40 and move stack/name information outside the circle.

**Rationale:** Pokerscope seats are significantly larger and only contain position text. Stack and player info lives below the circle, reducing clutter inside the badge.

**Status:** Decided

## DEC-004: Active player accent color change (amber → cyan/teal)

**Decision:** Replace `#fbbf24` (amber) active indicator with `~#06b6d4` (cyan/teal) to match Pokerscope.

**Rationale:** Pokerscope uses cyan/teal as the primary accent for active players and tags. Aligns the color palette.

**Status:** Decided
