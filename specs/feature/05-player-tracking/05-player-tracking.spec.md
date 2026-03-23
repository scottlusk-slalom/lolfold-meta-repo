---
type: feature
status: completed
priority: high
created: 2026-03-22
updated: 2026-03-22
tags: ["players", "notes", "intelligence", "core"]
related: ["04-hand-input-parsing"]
---

# Player Tracking & Intelligence Specification

## Problem Statement

As hands accumulate, the app needs to organize everything around players. A player's profile should be the single place to see everything you know about them: all hands you've played against them, any notes you've taken (tells, tendencies, behavioral observations), AI-generated tendency summaries, and basic stats. Players also need tags/archetypes and metadata like "last seen."

Additionally, player names will inevitably have duplicates or variations ("Pete" vs "Peter" vs "pete"). The system needs to handle this.

## Objectives

1. Player profile page showing all recorded intel on a person
2. Freeform notes system — add notes about a player any time (not just alongside a hand)
3. AI-generated tendency summaries when enough data exists
4. Player tags/archetypes (manual or AI-suggested)
5. Player comparison — side-by-side two players
6. Last seen date and session frequency
7. Name disambiguation and merge functionality

## Success Criteria

### Player Profiles
- [ ] Profile page shows: name, archetype tag, last seen, session count, hand count
- [ ] Full list of hands involving this player (linked to hand detail)
- [ ] AI-generated summary of tendencies (when 20+ hands exist)
- [ ] All notes sorted by date

### Notes
- [ ] User can add a note to any player from their profile
- [ ] Notes have a type: tell, tendency, behavioral, general
- [ ] Notes display with timestamp and who wrote them (in shared groups)
- [ ] Input is the same flow regardless of note type — the backend classifies it (or lets the user pick)

### Intelligence
- [ ] Auto-generated patterns surfaced on profile: "called your 3bets 6/7 times", "never check-raised the turn"
- [ ] Player archetype: user can set manually, or accept AI suggestion
- [ ] Last seen date auto-calculated from most recent hand
- [ ] Session frequency: how often this player appears in your sessions

### Comparison
- [ ] Select two players, see their stats/tendencies side by side
- [ ] Useful for table selection or deciding who to target

### Disambiguation
- [ ] System detects similar names and suggests merges
- [ ] User confirms merge — all hands and notes transfer to the canonical player record
- [ ] Aliases stored so future shorthand using the old name still links correctly

## Scope

### In Scope
- Player profile page (frontend)
- Player notes CRUD (frontend + API)
- AI tendency summary generation (API, via Bedrock)
- Player archetype tagging
- Player comparison view
- Last seen / session frequency
- Name disambiguation + merge

### Out of Scope
- Editing hand data from the player profile (go to the hand for that)
- Public player profiles or sharing outside the group
- Player photos/avatars

## Dependencies

- Spec 04 complete (hands exist in the database with linked players)
- Bedrock client working (from spec 02)

## Assumptions

- AI summaries are generated on-demand when viewing a profile, not pre-computed. For a POC with small data volumes, this is fine.
- Name similarity detection can use simple fuzzy matching (Levenshtein distance or similar). Doesn't need to be ML-powered.
- The notes input can be a single text box. The backend or AI can classify the note type, or the user can optionally tag it.

## References

- [Core PRD](../../../requirements/prd-core.md) — REQ-006 through REQ-008, REQ-021 through REQ-025
