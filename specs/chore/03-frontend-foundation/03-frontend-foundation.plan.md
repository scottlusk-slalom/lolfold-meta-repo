---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Frontend Foundation - Technical Implementation Plan

## Approach

Vite + React + TypeScript with Tailwind CSS. Mobile-first, dark mode by default. No authentication — just the app shell, routing, and an API client.

The app shell is a bottom tab bar (Hands, Players, Sessions, Profile) with a floating "New Hand" button that's always accessible. Placeholder pages for each route. The API client is a thin typed wrapper around fetch.

## Key Decisions & Constraints

- Tailwind with class-based dark mode, defaulting to dark
- React Router for routing
- No auth, no Cognito, no Amplify — just the shell
- API client must be designed so adding auth headers later is a one-line change (centralized header injection), not a change at every call site
- The "New Hand" button is the most important UX element — 1 tap from anywhere, always visible
- Routes: `/` (hands), `/players`, `/sessions`, `/profile`, `/hands/new`, `/hands/:id`, `/players/:id`, `/sessions/:id`
- Only env var needed: VITE_API_URL

## Milestones

- [ ] Vite + React + TS project scaffolded with Tailwind, builds locally
- [ ] App shell with bottom nav, dark mode, and "New Hand" FAB
- [ ] All routes wired with placeholder pages
- [ ] API client calls GET /health on load, handles errors
- [ ] Looks good on mobile (375px width)

## Affected Systems

- **lolfold-frontend** — All frontend code

## Notes

- Don't over-engineer state management. Local component state for now. Add zustand later if needed.
- Keep bottom tabs on all viewports for the POC — no need for a desktop sidebar variant.
- Poker rooms are dark. Make sure the dark mode contrast is comfortable, not harsh white-on-black.
