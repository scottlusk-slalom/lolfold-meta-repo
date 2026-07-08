# Execution Plan — bug/replayer-display-fixes

**Spec:** `specs/bug/replayer-display-fixes/SPEC.md`
**Type:** bug · **Quality gate:** standard · **Repos:** lolfold-frontend (single)
**Scope:** Presentation-only. No changes to replay logic, parsing, controls, or data.

## Summary

Four display bugs in the hand replayer poker table, all localized to
`src/components/replayer/PokerTable.tsx` (SVG felt), rendered via
`HandDetailPage.tsx → HandReplayer.tsx`. Data shape comes from
`useReplayerState.ts` (`step.players[]`: `position`, `folded`, `isHero`,
`stack`, `currentBet`).

## Dependency order

Single repo, single component. No cross-repo dependencies. One sub-agent
dispatched to `lolfold-frontend`.

## Per-fix task breakdown (all in `PokerTable.tsx`)

### Fix 1 — Every seat stays visible the whole hand
- Ensure the seat render loop iterates over all players for every step and
  never filters out folded / all-in / out-of-action players.
- Folded seats may be visually de-emphasized (dimmed) but position + name must
  persist. Root cause is likely a filter/conditional that drops the seat rather
  than only its cards.

### Fix 2 — Remove a player's CARDS on fold (seat remains)
- When `player.folded` is true at the current step, do not render that player's
  cards — both hero face-up and villain face-down.
- Keep the seat, name, position, stack. Decouple "render seat" from "render
  cards" so fold only affects cards.

### Fix 3 — Dealer button always shown at correct seat
- Current: `findIndex(p => /^(BU|BTN|D|Dealer|Button)$/i.test(p.position))`
  returns `-1` when no exact match → button not drawn.
- Make button-seat resolution robust:
  - Broaden matching (case-insensitive; handle `btn`/`button`/`dealer`/`d`/`bu`
    and common variants/whitespace).
  - Fallback: derive the button seat from hand data when the position label is
    absent/non-standard (inspect `useReplayerState.ts` for a dealer/button
    index or ordering that can be used).
  - Guarantee: button renders on every hand at the dealer seat.

### Fix 4 — A player's two cards drawn adjacent (side by side)
- Current: cards flank the seat (`seat.x - r - offset` and `seat.x + r + offset`)
  → opposite sides.
- Change so both cards render as a pair on one side of the seat icon, adjacent.
- Apply to both hero and non-hero card rendering.

## Integration points / considerations

- Mobile-first (Tailwind v4), dark mode correct, desktop + mobile.
- Replay logic/controls unchanged — presentation only.
- Reference `screenshots/` (PokerScope) is external look-and-feel inspiration
  only; do not copy non-table UI or match pixel-for-pixel.

## Verification (sub-agent pre-submit — MANDATORY)

- `npm ci`
- `npm run build` exits 0
- `npm run test:run` exits 0  (NOT `npm test` — that is vitest watch and hangs)
- `npx tsc -b --noEmit` exits 0
- Manually verify against a few real hands: one with a fold, one with a
  non-standard button position label.
- Add/adjust tests where practical: dealer-button placement across varied
  position labels; folded player retains seat but loses cards.

## Sub-agent dispatch

- Repo: lolfold-frontend
- Branch: `agent/bug/replayer-display-fixes/lolfold-frontend`
- Clone: https://github.com/scottlusk-slalom/lolfold-frontend.git
- On success: PR with label `sub-agent-complete`; one completion comment on
  status issue #11 ending with the wake marker.
