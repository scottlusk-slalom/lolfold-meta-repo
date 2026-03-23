---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Search & Filtering - Technical Implementation Plan

## Approach

Traditional filtering uses the denormalized fields on the Hand table — straightforward SQL WHERE clauses with joins to HandPlayer for villain filtering. Should feel instant.

AI search sends the user's natural language query to Claude along with hand summaries. For POC volumes (<1000 hands), we can afford to send batch summaries and let Claude pick the relevant ones. At scale this would need embeddings + vector search, but that's way overkill here.

"Hands like this" extracts key features from a source hand (villain, position, pot type, board texture, action line) and finds similar hands — combination of SQL filtering and optionally an AI similarity assessment.

This spec also builds the hand list page and hand detail page, which are core navigation surfaces used everywhere.

## Key Decisions & Constraints

- Filters: villain (dropdown), hero position, pot type (SRP/3bet/4bet), num players, street reached. All combinable with AND logic.
- The hand list item component is reusable — it appears on the hands list, search results, player profiles, and session detail. Get it right.
- AI search strategy: try having Claude translate NL query → filter params first. Fall back to batch scan if the query is too complex.
- Hand detail page is where the replayer will live (spec 07 adds it). Build the page structure now with the structured text view.

## Milestones

- [ ] Hands list page with working filter controls
- [ ] Reusable hand list item component
- [ ] Hand detail page with full structured view + raw input
- [ ] AI-powered natural language search
- [ ] "Hands like this" from any hand detail

## Affected Systems

- **lolfold-api** — Filtering endpoint, AI search endpoint, similar hands endpoint
- **lolfold-frontend** — Hands list, hand detail, search UI, hand list item component

## Notes

- Consider caching AI search results briefly so hitting "back" doesn't re-trigger a Bedrock call.
- The hand detail page should have a clear spot for the replayer to slot in later — maybe a tab or section that spec 07 fills in.
