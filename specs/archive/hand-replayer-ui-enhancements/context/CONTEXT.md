# Context — hand-replayer-ui-enhancements

## Source Documents

| Document | Relevance |
|----------|-----------|
| `project/product-brief.md` | Hand Replayer defined as core capability |
| `requirements/prd-core.md` (REQ-011, REQ-012, REQ-013) | Replayer functional requirements |
| `architecture/legacy/00-lolfold.md` | System overview and tech stack |
| `repos/lolfold-frontend/src/components/replayer/` | Current replayer implementation |
| `repos/lolfold-frontend/src/pages/HandDetailPage.tsx` | Current page layout (side-by-side grid) |

## Key Observations

1. **Current layout**: `HandDetailPage` uses `lg:grid-cols-2` — replayer left, hand details right. This splits horizontal space 50/50, making the table SVG small on most screens.
2. **SVG viewBox**: `520x380` — wider than tall. The table benefits from horizontal space.
3. **No reference to Pokerscope styling**: Current UI uses generic dark theme with minimal felt/table styling. No player names displayed at seats (only positions).
4. **Mobile stacking**: Already stacks vertically on mobile (`grid-cols-1`), but the table is still small due to padding/constraints.

## Reference Material

- [x] Pokerscope UI screenshot: `context/Screenshot 2026-07-01 at 10.59.42 AM.png`
- [x] Visual analysis: `context/pokerscope-analysis.md`
