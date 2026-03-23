---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Player Tracking & Intelligence - Technical Implementation Plan

## Approach

The player profile aggregates data from Player, Hand (via HandPlayer), and PlayerNote tables. Most of this is straightforward CRUD + queries. The interesting parts are the AI tendency summary (send a player's hands + notes to Claude, get a scouting report back) and the auto-detected patterns (simple aggregation queries, no AI needed).

Name disambiguation uses fuzzy matching (pg_trgm or Levenshtein in app code). Merge is a transactional operation that moves all HandPlayer and PlayerNote records to the canonical player and stores the old name as an alias.

## Key Decisions & Constraints

- AI summaries generated on-demand, not pre-computed. Fine for POC volumes.
- Auto-detected patterns should work on very small samples — even "3bet 2/2 times" is useful. Don't hide behind arbitrary thresholds.
- Player merge must be transactional (moves hands, notes, adds alias, deletes old player in one transaction)
- Notes input is a single text box with optional type selector (tell, tendency, behavioral, general). If no type selected, default to "general" or auto-classify with a quick AI call.
- The AI summary prompt should produce a scouting report style output with specific hand references.

## Milestones

- [ ] Player list and profile pages with hand count, last seen, notes
- [ ] Add/edit/delete notes on player profiles
- [ ] AI tendency summary on profiles (when enough hands exist)
- [ ] Auto-detected frequency patterns (3bet %, fold to cbet, etc.)
- [ ] Player archetype tagging (manual + AI-suggested)
- [ ] Player comparison view
- [ ] Name disambiguation detection and merge flow

## Affected Systems

- **lolfold-api** — Player endpoints, notes endpoints, AI summary, merge logic
- **lolfold-frontend** — Player list, profile, comparison, merge UI

## Notes

- The merge UI should show what will happen before confirming: "12 hands and 3 notes will be moved to [name]."
- Consider caching AI summaries briefly (even just in-memory with a short TTL) to avoid re-generating on every profile view.
