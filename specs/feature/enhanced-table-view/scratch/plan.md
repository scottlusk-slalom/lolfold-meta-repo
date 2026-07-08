# Execution Plan — feature/enhanced-table-view

## ⚠️ OPEN QUESTION FOR HUMAN (resolve at plan-review)

**Which "table" is this spec about?** The SPEC.md *text* describes a data
table ("rows/columns", "cramped rows", "scan the data"). But the reference
screenshot (`screenshots/Screenshot 2026-07-01 at 10.59.42 AM.png`) is the URL
`pokerscope.app/hand/...` showing the **poker hand replayer** — the oval felt
"table" with seats/cards (rendered by `PokerTable.tsx`), *not* a data grid.

This plan assumes the reference screenshot is authoritative: **"table view" =
the poker replayer table on the Hand Detail page.** If the human instead means
a data grid (e.g. the hands list on `HandsPage.tsx`), the plan changes and must
be re-approved. **Please confirm in the plan-review decision.**

Secondary note: the spec expected two screenshots (`current.png` + `target.png`);
only one image was provided. Enlargement magnitude will be judged against the
single reference + acceptance criteria ("visibly larger").

## Repos

- `lolfold-frontend` (only). Single-repo, frontend-only, layout/presentation.

## Target component (screenshot interpretation)

Render chain for `pokerscope.app/hand/<id>`:
`HandDetailPage.tsx` → `components/replayer/HandReplayer.tsx` → `components/replayer/PokerTable.tsx`

Width is constrained by nested containers:
- `AppShell.tsx`:  `mx-auto max-w-5xl`   (outer page)
- `HandReplayer.tsx`: `max-w-4xl mx-auto` (the binding constraint — narrower than shell)
- `PokerTable.tsx`: `<svg viewBox="0 0 600 440" className="w-full">` — scales to
  its container, so **widening the container automatically enlarges the whole
  table** (seats, chips, text scale with it). No viewBox/geometry math needed.

## Tasks

1. **Confirm component** (guard against the ambiguity above). Search
   `src/components/` and `src/pages/` to re-verify the replayer table is what
   the screenshot shows before editing.
2. **Full width:** relax the width cap so the table spans the page. Options,
   prefer least-invasive Tailwind change:
   - Raise/remove `max-w-4xl` on `HandReplayer.tsx` (e.g. to `max-w-6xl`/`max-w-7xl`
     or full-bleed within the shell's `max-w-5xl`), and/or widen the `AppShell`
     container for this route. Keep within the app's normal page padding —
     must NOT overflow off-screen.
3. **Larger / more legible:** because the SVG scales with width, widening
   already enlarges rows/text. If further legibility is needed, adjust font
   sizes / seat radii / spacing in `PokerTable.tsx` to match the reference.
4. **Responsive:** verify mobile (mobile-first, Tailwind v4). Full-width on
   desktop must not break narrow viewports — the `w-full` SVG already handles
   scaling; confirm no fixed widths introduced.
5. **Dark mode:** app default; confirm colors unchanged and correct.
6. **No behavior/data change** — presentation only.

## Testing

- Existing test: `components/replayer/__tests__/HandReplayer.test.tsx`
  (asserts SVG `role="img" name="Poker table"`, seat labels). Must still pass.
- Add/adjust a test covering the new layout where practical (e.g. assert the
  container no longer carries the narrow `max-w-4xl` cap, or an appropriate
  width class is present).

## Verification gates (sub-agent, MANDATORY pre-submit)

- `npm ci`
- `npm run build`   → exit 0
- `npm run test:run` → exit 0   (NOT `npm test` — that is vitest watch, hangs)
- `npx tsc -b --noEmit` → exit 0

## Quality gate

- `standard` → plan-review (PAUSE, this gate) + pr-review (PAUSE after PR).

## Branch / PR

- Work branch (metarepo PR convention): `agent/feature/enhanced-table-view/lolfold-frontend`
- One PR on `lolfold-frontend`, label `sub-agent-complete`.
- Post completion comment to metarepo status issue #8 with wake marker.
