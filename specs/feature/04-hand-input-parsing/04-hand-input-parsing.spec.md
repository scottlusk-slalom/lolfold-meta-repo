---
type: feature
status: completed
priority: high
created: 2026-03-22
updated: 2026-03-22
tags: ["hand-input", "ai-parsing", "bedrock", "core"]
related: ["02-api-foundation", "03-frontend-foundation"]
---

# Hand Input & AI Parsing Specification

## Problem Statement

This is the core feature of the app. A player at a poker table needs to record a hand in 30 seconds between deals. They type messy shorthand on their phone and the app needs to turn it into a structured, searchable, replayable hand record. The AI parsing has to be flexible enough to handle variations in shorthand but honest enough to say "I can't figure this out" when it can't.

## Objectives

1. Build the hand input UI — a text area optimized for fast, one-handed phone typing
2. Implement the AI parsing pipeline: send shorthand to Claude via Bedrock, get back a structured hand
3. Show the parsed hand to the user with confidence indicators, let them confirm or correct
4. Save the hand with both raw input and structured data
5. Handle parse failures gracefully — save the raw note, tell the user what went wrong

## Success Criteria

### Input
- [ ] "New Hand" button opens a full-screen text input (or near-full-screen)
- [ ] User can type shorthand and submit
- [ ] Input is not lost if the connection drops (persist in local storage until confirmed)

### Parsing
- [ ] Claude parses shorthand into a structured hand with: players, positions, stack sizes, blinds/straddles, and action per street with exact bet sizes
- [ ] Multiway pots are handled correctly
- [ ] Game variants (straddles, 7-2 bounty, etc.) are captured in metadata
- [ ] Parsing returns in under 3 seconds in typical cases
- [ ] Confidence indicators highlight uncertain fields
- [ ] When parsing fails, the user sees a clear explanation of what couldn't be resolved

### Confirmation
- [ ] Parsed hand is displayed in a readable structured format
- [ ] User can confirm (save), edit fields, or re-submit with corrections
- [ ] Original raw input is always preserved alongside the structured data

### Data
- [ ] Hand saved to PostgreSQL with all fields populated
- [ ] Players mentioned in the hand are auto-created or linked to existing player records
- [ ] HandPlayer join records created with correct positions and stack sizes
- [ ] Denormalized fields on Hand (hero_position, pot_type, street_reached, num_players) are populated for efficient filtering later

## Scope

### In Scope
- Hand input text area UI
- API endpoint for hand submission
- Claude prompt engineering for shorthand parsing
- Structured hand response format definition
- Confidence scoring
- Confirmation/edit UI
- Raw input preservation
- Auto-creation of player records from hand data
- Local storage draft persistence

### Out of Scope
- Hand list view / browsing (spec 06)
- Player profile pages (spec 05)
- Hand replayer (spec 07)
- Session association (spec 08 — hands can be created without a session for now)
- Shorthand quick-start buttons (future enhancement)

## Shorthand Notation

The app should document a recommended shorthand format, but the AI should handle reasonable variations. Here's what the input looks like in practice:

**Example 1 — 3bet pot:**
```
tom 20 co 1750e. H 3b bu 80. bb cc 1200e. tom c.
F Jh9d2c. x, tom 35, H c, bb f.
T 7s. x x.
R Ks. H 80. tom f.
```

**Translation:** Tom opens to 20 from CO with 1750 effective. Hero 3bets to 80 from BU. BB cold calls with 1200 effective. Tom calls. Flop Jh9d2c, check, Tom bets 35, Hero calls, BB folds. Turn 7s, check check. River Ks, Hero bets 80, Tom folds.

**Key conventions:**
- Player names in lowercase, Hero = H
- Positions: UTG, HJ/LJ, CO, BU/BTN, SB, BB
- Stack sizes noted as effective (e = effective, meaning Hero covers)
- bet/raise amounts as numbers, 3b = 3bet, cc = cold call, c = call, f = fold, x = check
- Streets separated by F (flop), T (turn), R (river) with board cards
- Periods or line breaks separate actions

The AI needs to handle variations of this — different ordering, missing periods, abbreviated or misspelled positions, etc. When something is ambiguous, flag it rather than guess.

## Dependencies

- Specs 01-03 complete (infra, API, frontend all running)
- Bedrock access to Claude working (verified in spec 02)

## Assumptions

- The parsed hand JSON structure will be defined as part of this spec's implementation — it doesn't need to be locked down beforehand
- Players are matched by name (case-insensitive). Exact dedup/merge is handled in spec 05.
- The prompt engineering for Claude will take iteration — expect to refine the system prompt based on real examples

## References

- [Core PRD](../../../requirements/prd-core.md) — REQ-001 through REQ-005, REQ-019, REQ-020
- [API Foundation](../../chore/02-api-foundation/02-api-foundation.plan.md) — database schema, Bedrock client
